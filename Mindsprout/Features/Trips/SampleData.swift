import Foundation
import SwiftData

@MainActor
enum SampleData {
    static func seedIfEmpty(context: ModelContext, mediaStore: any MediaStoring) {
        let existing = (try? context.fetchCount(FetchDescriptor<Trip>())) ?? 0
        guard existing == 0 else { return }
        seed(context: context, mediaStore: mediaStore)
    }

    static func seed(context: ModelContext, mediaStore: any MediaStoring) {
        var seedCounter = 0
        func photoAsset(_ symbol: String) -> MediaAsset {
            seedCounter += 1
            let data = PlaceholderMedia.photoPNG(seed: seedCounter, symbol: symbol)
            let path = (try? mediaStore.write(data, kind: .photo, fileExtension: "png")) ?? ""
            let asset = MediaAsset(kind: .photo, relativePath: path)
            context.insert(asset)
            return asset
        }
        func audioAsset() -> MediaAsset {
            let data = PlaceholderMedia.toneWAV()
            let path = (try? mediaStore.write(data, kind: .audio, fileExtension: "wav")) ?? ""
            let asset = MediaAsset(kind: .audio, relativePath: path)
            context.insert(asset)
            return asset
        }

        let cal = Calendar.current
        func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
            cal.date(from: DateComponents(year: y, month: m, day: d)) ?? Date()
        }

        // Tasmania — oldest, REVISIT
        let tasmania = Trip(
            destination: "Tasmania", country: "Australia",
            startDate: date(2025, 2, 2), endDate: date(2025, 2, 9),
            type: .friends,
            expectations: ["Explore somewhere none of us have been", "Try new things together"],
            createdAt: date(2025, 2, 10)
        )
        tasmania.theme = "Wonder came slowly"
        tasmania.headlineMemory = "The light on Cradle Mountain made the whole valley glow."
        context.insert(tasmania)
        seedReflections(
            into: context, trip: tasmania, count: 9, calendar: cal,
            place: "Cradle Mountain", symbols: ["mountain.2.fill", "leaf.fill", "sun.max.fill"],
            photoAsset: photoAsset, audioAsset: nil,
            text: "We hiked for hours and the wilderness just kept opening up in front of us."
        )
        tasmania.coverAssetID = photoAsset("mountain.2.fill").id

        // Seoul — REVISIT
        let seoul = Trip(
            destination: "Seoul", country: "South Korea",
            startDate: date(2024, 10, 3), endDate: date(2024, 10, 8),
            type: .business,
            expectations: ["Discover the city between meetings", "Get inspired by a new environment"],
            createdAt: date(2024, 10, 9)
        )
        seoul.theme = "The city never slept, neither did I"
        seoul.headlineMemory = "Late-night street food after the conference wrapped."
        context.insert(seoul)
        seedReflections(
            into: context, trip: seoul, count: 11, calendar: cal,
            place: "Myeongdong", symbols: ["building.2.fill", "fork.knife", "moon.stars.fill"],
            photoAsset: photoAsset, audioAsset: nil,
            text: "Slipped out between sessions and let the neon pull me through the back streets."
        )
        seoul.coverAssetID = photoAsset("building.2.fill").id

        // Kyoto — newest, ACTIVE (fallback: most recently created)
        let kyoto = Trip(
            destination: "Kyoto", country: "Japan",
            startDate: date(2024, 4, 12), endDate: date(2024, 4, 21),
            type: .solo,
            expectations: ["Clear my head and reset", "Step outside my comfort zone"],
            createdAt: date(2026, 5, 30)
        )
        kyoto.theme = "Stillness I didn't know I needed"
        kyoto.headlineMemory = "When I took the bullet train from Tokyo, I was hoping to get some relief in my new destination."
        context.insert(kyoto)

        let coverPhoto = photoAsset("tree.fill")
        kyoto.coverAssetID = coverPhoto.id

        let kyotoDays: [(Int, String, String)] = [
            (1, "Gion", "First evening wandering Gion, the lanterns flickering on as the light went soft."),
            (2, "Fushimi Inari", "Climbed through a thousand vermilion gates until the crowds thinned to nothing."),
            (3, "Arashiyama", "When I took the bullet train from Tokyo, I was hoping to get some relief in my new destination. A place where bustling streets are replaced by nature, temples and peace. That place was Kyoto. It was a magical yet simple experience walking through the Arashiyama bamboo forest while wearing the kimono. Nature has never felt more intimate, especially with a place I've never been to before.")
        ]
        for (day, place, text) in kyotoDays {
            let reflection = Reflection(
                tripID: kyoto.id, dayIndex: day,
                date: cal.date(byAdding: .day, value: day - 1, to: kyoto.startDate) ?? kyoto.startDate,
                highlightPrompt: "The moment that stayed with me",
                locationLabel: place,
                bodyKind: .text, text: text,
                isDraft: false
            )
            reflection.moodTags = ["Serenity", "Curiosity"]
            let photos = (0..<6).map { photoAsset(["tree.fill", "leaf.fill", "camera.fill", "building.columns.fill", "sun.max.fill", "figure.walk"][$0]) }
            reflection.photoAssetIDs = photos.map(\.id)
            if day == 3 {
                reflection.audioAssetID = audioAsset().id
            }
            reflection.xpAwarded = 50
            context.insert(reflection)
        }
        // Pad to 14 committed memories with lightweight text-only days.
        for day in 4...14 {
            let reflection = Reflection(
                tripID: kyoto.id, dayIndex: day,
                date: cal.date(byAdding: .day, value: day - 1, to: kyoto.startDate) ?? kyoto.startDate,
                highlightPrompt: "A small thing I noticed",
                locationLabel: "Kyoto",
                bodyKind: .text,
                text: "Day \(day): a quiet tea house, a temple garden, the smell of cedar after rain.",
                isDraft: false
            )
            reflection.xpAwarded = 50
            context.insert(reflection)
        }

        try? context.save()
    }

    private static func seedReflections(
        into context: ModelContext, trip: Trip, count: Int, calendar: Calendar,
        place: String, symbols: [String],
        photoAsset: (String) -> MediaAsset, audioAsset: (() -> MediaAsset)?,
        text: String
    ) {
        for day in 1...count {
            let reflection = Reflection(
                tripID: trip.id, dayIndex: day,
                date: calendar.date(byAdding: .day, value: day - 1, to: trip.startDate) ?? trip.startDate,
                highlightPrompt: "The moment that stayed with me",
                locationLabel: place,
                bodyKind: .text, text: text,
                isDraft: false
            )
            reflection.moodTags = ["Wonder", "Calm"]
            if day <= 3 {
                let photos = (0..<3).map { photoAsset(symbols[$0 % symbols.count]) }
                reflection.photoAssetIDs = photos.map(\.id)
            }
            reflection.xpAwarded = 50
            context.insert(reflection)
        }
    }
}
