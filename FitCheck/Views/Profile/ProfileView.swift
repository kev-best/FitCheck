import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var theme: Theme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Circle().fill(.gray.opacity(0.2)).frame(width: 64, height: 64)
                        .overlay(Text(String(app.currentUser.displayName.prefix(1))).font(.title3.bold()))
                    VStack(alignment: .leading) {
                        Text(app.currentUser.displayName).font(.headline)
                        Text("@\(app.currentUser.username)").font(.subheadline).foregroundStyle(.secondary)
                        HStack {
                            Image(systemName: "flame.fill").foregroundStyle(.orange, .red)
                            Text("Streak \(app.currentUser.streakCount)").font(.footnote.bold())
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)

                HStack {
                    StatCard(title: "Friends", value: "\(app.currentUser.friends.count)")
                    StatCard(title: "Posts", value: "\(max(1, app.currentUser.streakCount))")
                    StatCard(title: "Reacts", value: "42")
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings").font(.headline)
                    VStack(spacing: 12) {
                        SettingRow(icon: "lock.fill", title: "Privacy", subtitle: "Face blur, background blur, location off")
                        SettingRow(icon: "bell.badge.fill", title: "Notifications", subtitle: "Daily Fit Call")
                        SettingRow(icon: "hand.raised.fill", title: "Community Guidelines", subtitle: "Report & block controls")
                    }
                    .padding()
                    .softCard(cornerRadius: 20, shadow: theme.shadow)
                }
                .padding(.horizontal)

                Spacer(minLength: 80)
            }
            .padding(.top)
        }
        .background(theme.bg.ignoresSafeArea())
    }
}

struct StatCard: View {
    var title: String
    var value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.title3.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct SettingRow: View {
    var icon: String
    var title: String
    var subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
