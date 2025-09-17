import SwiftUI

struct FeedView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var router: Router

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DailyPromptBanner()
                    .padding(.horizontal)

                ForEach(app.feed) { post in
                    PostCard(post: post)
                        .padding(.horizontal)
                        .onTapGesture {
                            router.push(.postDetail(id: post.id), in: .feed)
                        }
                }
                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
        .background(theme.bg)
    }
}

struct DailyPromptBanner: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var router: Router

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(app.dailyWindowActive ? "Fit Call is LIVE" : "Next Fit Call soon")
                    .font(.headline.bold())
                Text(app.dailyWindowActive ? "You’ve got 2 minutes to capture your outfit." : "You’ll be notified when it’s time.")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
            if app.dailyWindowActive {
                Button {
                    router.select(.fitCheck)   // ⬅️ jump to camera tab
                } label: {
                    Text("FitCheck").font(.callout.bold())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(theme.gradient)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(radius: 8)
            }
        }
        .padding()
        .softCard(cornerRadius: theme.cornerRadius, shadow: theme.shadow)
    }
}


struct PostCard: View {
    let post: Post
    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(.gray.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(Text(String(post.user.displayName.prefix(1))).font(.subheadline.bold()))
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(post.user.displayName).font(.subheadline.bold())
                        if post.isLate {
                            Text("LATE")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.red.gradient)
                                .clipShape(Capsule())
                        }
                    }
                    Text(post.createdAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    ForEach(post.palette.indices, id: \.self) { idx in
                        RoundedRectangle(cornerRadius: 6).fill(post.palette[idx])
                            .frame(width: 16, height: 16)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.6), lineWidth: 0.5))
                    }
                }
            }

            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
                .overlay(
                    HStack(spacing: 8) {
                        DemoImage(name: post.backImageName)
                        DemoImage(name: post.frontImageName)
                    }
                    .padding(8)
                )
                .frame(height: 300)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(post.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.06))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 2)
            }

            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "face.smiling")
                    Text("\(post.reactions.count)")
                }
                HStack(spacing: 6) {
                    Image(systemName: "text.bubble")
                    Text("\(post.comments.count)")
                }
                Spacer()
                Button { /* react */ } label: { Text("React") }
                    .pill(theme)
            }
            .font(.subheadline)
        }
        .padding(14)
        .softCard(cornerRadius: 24, shadow: theme.shadow)
    }
}

struct DemoImage: View {
    var name: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.6))
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .bottomTrailing) {
                    Text(name)
                        .font(.caption2)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(6)
                }
        }
    }
}
