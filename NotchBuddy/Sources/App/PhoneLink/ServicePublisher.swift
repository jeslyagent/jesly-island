#if PHONE_LINK
import AppKit
import CloudKit
import Combine

// MARK: - Services on the iPhone
//
// One `Service` record per service Mochi (GitHub, Stripe, Vercel, Resend,
// Cal.com, n8n, Notion), built from the data the Mac's pollers already keep in
// AppState: no extra API call, no key sent anywhere. The whole snapshot
// (amounts, titles, emails, links) is one field encrypted with the user's
// iCloud keys; only the pill ID, the state dot and the date are in clear.
// Driven by AppState changes (debounced), never by a timer.

@MainActor
final class ServicePublisher {
    static let shared = ServicePublisher()

    private let container = CKContainer(identifier: CloudProbe.containerID)
    private var database: CKDatabase { container.privateCloudDatabase }
    private var cancellable: AnyCancellable?
    private var published: [String: ServiceSnapshot] = [:]
    private var cleanedUp = false
    private var writing = false
    private var again = false

    func start() {
        guard cancellable == nil else { return }
        let s = AppState.shared
        let changes: [AnyPublisher<Void, Never>] = [
            s.$stripePayments.map { _ in () }.eraseToAnyPublisher(),
            s.$stripeBalance.map { _ in () }.eraseToAnyPublisher(),
            s.$stripeError.map { _ in () }.eraseToAnyPublisher(),
            s.$githubPulse.map { _ in () }.eraseToAnyPublisher(),
            s.$githubActivity.map { _ in () }.eraseToAnyPublisher(),
            s.$vercelDeployments.map { _ in () }.eraseToAnyPublisher(),
            s.$resendEmails.map { _ in () }.eraseToAnyPublisher(),
            s.$calcomBookings.map { _ in () }.eraseToAnyPublisher(),
            s.$calcomError.map { _ in () }.eraseToAnyPublisher(),
            s.$notionPages.map { _ in () }.eraseToAnyPublisher(),
            s.$notionError.map { _ in () }.eraseToAnyPublisher(),
            s.$n8nRuns.map { _ in () }.eraseToAnyPublisher(),
        ]
        cancellable = Publishers.MergeMany(changes)
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] in
                MainActor.assumeIsolated { self?.publish() }
            }
        log("service publisher on")
    }

    /// Stops and deletes this Mac's services from iCloud.
    func stop() {
        cancellable = nil
        let ids = PillCatalog.phoneServices.map {
            CKRecord.ID(recordName: ServiceSnapshot.recordName(for: $0), zoneID: SessionSnapshot.zoneID)
        }
        published = [:]
        cleanedUp = false
        Task { _ = try? await database.modifyRecords(saving: [], deleting: ids, savePolicy: .changedKeys, atomically: false) }
        log("service publisher off")
    }

    private func publish() {
        guard !writing else { again = true; return }
        writing = true
        let snapshots = ServiceSnapshots.all(from: AppState.shared)
        Task {
            await write(snapshots)
            writing = false
            if again { again = false; publish() }
        }
    }

    private func write(_ snapshots: [String: ServiceSnapshot]) async {
        var deletions: [CKRecord.ID] = []
        if !cleanedUp {
            // Services this Mac no longer has (key removed since the last run).
            deletions = PillCatalog.phoneServices.filter { snapshots[$0] == nil }.map {
                CKRecord.ID(recordName: ServiceSnapshot.recordName(for: $0), zoneID: SessionSnapshot.zoneID)
            }
            cleanedUp = true
        }
        let changed = snapshots.values.filter { snapshot in
            guard let old = published[snapshot.pillId] else { return true }
            return !old.sameContent(as: snapshot)
        }
        let removed = published.keys.filter { snapshots[$0] == nil }
        deletions += removed.map { CKRecord.ID(recordName: ServiceSnapshot.recordName(for: $0), zoneID: SessionSnapshot.zoneID) }
        guard !changed.isEmpty || !deletions.isEmpty else { return }

        let records = changed.compactMap { record(for: $0) }
        do {
            let result = try await database.modifyRecords(saving: records, deleting: deletions,
                                                          savePolicy: .changedKeys, atomically: false)
            for (id, outcome) in result.saveResults {
                guard let pillId = ServiceSnapshot.pillId(fromRecordName: id.recordName) else { continue }
                if case .success = outcome { published[pillId] = snapshots[pillId] }
            }
            for id in removed { published[id] = nil }
            let names = changed.map { "\($0.pillId.replacingOccurrences(of: "integration_", with: ""))=\($0.tone.rawValue)" }
            log("published \(changed.count) service(s) [\(names.sorted().joined(separator: ", "))], removed \(deletions.count)")
        } catch {
            log("publish failed: \(error.localizedDescription)")
        }
    }

    private func record(for snapshot: ServiceSnapshot) -> CKRecord? {
        guard let json = try? JSONEncoder().encode(snapshot), let payload = String(data: json, encoding: .utf8) else { return nil }
        let record = CKRecord(recordType: ServiceSnapshot.recordType,
                              recordID: CKRecord.ID(recordName: ServiceSnapshot.recordName(for: snapshot.pillId),
                                                    zoneID: SessionSnapshot.zoneID))
        record["pillId"] = snapshot.pillId
        record["tone"] = snapshot.tone.rawValue
        record["updatedAt"] = snapshot.updatedAt
        record["macName"] = Host.current().localizedName ?? ""
        record.encryptedValues["payload"] = payload
        return record
    }

    private func log(_ message: String) {
        CloudProbe.shared.log("[services] \(message)")
    }
}

// MARK: - Building the snapshots

/// One snapshot per service that has data on this Mac. A service without its
/// key (nothing loaded) is left out, and the iPhone shows "connect it on your Mac".
@MainActor
enum ServiceSnapshots {
    static func all(from s: AppState) -> [String: ServiceSnapshot] {
        let built = [github(s), vercel(s)].compactMap { $0 }
        return Dictionary(uniqueKeysWithValues: built.map { ($0.pillId, $0) })
    }

    // MARK: GitHub

    static func github(_ s: AppState) -> ServiceSnapshot? {
        guard let pulse = s.githubPulse else { return nil }
        func tone(_ ci: CIState) -> ServiceTone {
            switch ci {
            case .success: .ok
            case .failure: .error
            case .pending: .warning
            case .unknown: .idle
            }
        }
        func ciLabel(_ ci: CIState) -> String {
            switch ci {
            case .success: "checks passed"
            case .failure: "checks failing"
            case .pending: "checks running"
            case .unknown: "no checks"
            }
        }
        func reviewLabel(_ review: ReviewState) -> String {
            switch review {
            case .approved: " · approved"
            case .changesRequested: " · changes requested"
            case .pending: " · review required"
            case .unknown: ""
            }
        }
        let failingPR = pulse.myPRs.first { $0.ci == .failure }
        let failingMain = pulse.mainCI.first { $0.ci == .failure }
        let pending = pulse.myPRs.contains { $0.ci == .pending } || pulse.mainCI.contains { $0.ci == .pending }
        let anyGreen = pulse.myPRs.contains { $0.ci == .success } || pulse.mainCI.contains { $0.ci == .success }

        let overall: ServiceTone
        let reason: String
        if let main = failingMain {
            overall = .error
            reason = "CI failing on \(main.repo) · \(main.branch)"
        } else if let pr = failingPR {
            overall = .error
            reason = "Checks failing on \(pr.repo) #\(pr.number): \(pr.title)"
        } else if pending {
            overall = .warning
            reason = "Checks are running"
        } else if !pulse.toReview.isEmpty {
            overall = .warning
            reason = pulse.toReview.count == 1
                ? "1 pull request waits for your review"
                : "\(pulse.toReview.count) pull requests wait for your review"
        } else if anyGreen {
            overall = .ok
            reason = "All checks passed"
        } else {
            overall = .idle
            reason = "Nothing going on"
        }

        var sections: [ServiceSection] = []
        if !pulse.myPRs.isEmpty {
            sections.append(ServiceSection(title: "Your pull requests", items: pulse.myPRs.prefix(8).map {
                ServiceItem(title: "#\($0.number) \($0.title)",
                            detail: "\($0.repo) · \(ciLabel($0.ci))\(reviewLabel($0.review))\($0.isDraft ? " · draft" : "")",
                            tone: tone($0.ci), url: $0.url)
            }))
        }
        if !pulse.toReview.isEmpty {
            sections.append(ServiceSection(title: "Waiting for your review", items: pulse.toReview.prefix(8).map {
                ServiceItem(title: "#\($0.number) \($0.title)", detail: $0.repo, tone: .warning, url: $0.url)
            }))
        }
        if !pulse.mainCI.isEmpty {
            sections.append(ServiceSection(title: "Default branches", items: pulse.mainCI.prefix(8).map {
                ServiceItem(title: $0.repo, detail: "\($0.branch) · \(ciLabel($0.ci))", tone: tone($0.ci), url: $0.url)
            }))
        }
        var headline = "\(pulse.myPRs.count) open pull request\(pulse.myPRs.count == 1 ? "" : "s")"
        if let total = s.githubActivity?.total { headline += " · \(total) contributions this year" }
        return ServiceSnapshot(pillId: "integration_github", tone: overall, headline: headline, reason: reason,
                               sections: sections, updatedAt: pulse.fetchedAt)
    }

    // MARK: Vercel

    static func vercel(_ s: AppState) -> ServiceSnapshot? {
        let filter = s.vercelProjectFilter
        let deployments = filter.isEmpty ? s.vercelDeployments : s.vercelDeployments.filter { filter.contains($0.projectName) }
        guard let latest = deployments.first else { return nil }
        func tone(_ d: VercelDeployment) -> ServiceTone {
            d.isSuccess ? .ok : (d.state == "CANCELED" ? .warning : .error)
        }
        let branch = latest.branch.map { " · \($0)" } ?? ""
        let reason: String
        switch latest.state {
        case "READY": reason = "Last deploy is live: \(latest.projectName)\(branch)"
        case "CANCELED": reason = "Last deploy was canceled: \(latest.projectName)\(branch)"
        default: reason = "Last deploy failed: \(latest.projectName)\(branch)"
        }
        let items = deployments.prefix(10).map { d in
            ServiceItem(title: d.projectName,
                        detail: [d.statusLabel, d.branch, d.commitMessage].compactMap { $0 }.joined(separator: " · "),
                        tone: tone(d), date: d.createdAt,
                        url: d.url.isEmpty ? nil : "https://\(d.url)")
        }
        return ServiceSnapshot(pillId: "integration_vercel", tone: tone(latest),
                               headline: "\(latest.projectName) · \(latest.statusLabel)", reason: reason,
                               sections: [ServiceSection(title: "Deployments", items: items)],
                               updatedAt: latest.createdAt)
    }
}
#endif
