import Foundation
@testable import StartMe

/// One fixture: a raw typed-in task, and the category it should classify
/// as. `expectedCategory == nil` means "don't assert a specific category
/// for this one" (vague/typo/unicode/gibberish inputs) — those fixtures
/// still must satisfy the general starter-action invariants.
struct StarterFixture {
    let input: String
    let expectedCategory: TaskCategory?
    let note: String

    init(_ input: String, _ expectedCategory: TaskCategory?, _ note: String) {
        self.input = input
        self.expectedCategory = expectedCategory
        self.note = note
    }
}

/// 60+ fixtures spanning every category in docs/PRODUCT_SPEC.md plus vague,
/// slang, typo, short, long, Unicode, and special-character edge cases.
/// Every fixture must satisfy the invariant checked in
/// `StarterFixtureTests`: the returned action is smaller than the task.
enum StarterFixtures {
    static let all: [StarterFixture] = [
        // MARK: - Cleaning: apartment, kitchen, bathroom, bedroom
        StarterFixture("clean my entire apartment", .cleaning, "spec example"),
        StarterFixture("clean my kitchen", .cleaning, "spec example"),
        StarterFixture("clean the bathroom", .cleaning, "kitchen/bath/bed sweep"),
        StarterFixture("clean my bedroom", .cleaning, "kitchen/bath/bed sweep"),
        StarterFixture("tidy the living room", .cleaning, "cleaning synonym"),
        StarterFixture("vacuum the house", .cleaning, "cleaning synonym"),
        StarterFixture("mop the kitchen floor", .cleaning, "cleaning synonym"),

        // MARK: - Dishes
        StarterFixture("do the dishes", .dishes, "dishes"),
        StarterFixture("wash the dishes in the sink", .dishes, "dishes"),
        StarterFixture("load the dishwasher", .dishes, "dishes"),

        // MARK: - Laundry
        StarterFixture("do my laundry", .laundry, "laundry"),
        StarterFixture("put clothes in the washer", .laundry, "laundry"),
        StarterFixture("fold the laundry", .laundry, "laundry"),

        // MARK: - Studying / homework / essays
        StarterFixture("start studying for my exam", .studying, "studying"),
        StarterFixture("do my homework", .studying, "homework"),
        StarterFixture("finish my essay", .studying, "essay"),
        StarterFixture("study for the bar exam", .studying, "studying"),
        StarterFixture("read the textbook chapter", .studying, "studying"),

        // MARK: - Résumé / writing
        StarterFixture("work on my résumé", .writing, "résumé, accented"),
        StarterFixture("update my resume", .writing, "resume, ascii"),
        StarterFixture("write my cover letter", .writing, "writing"),
        StarterFixture("draft a blog post", .writing, "writing"),

        // MARK: - Email
        StarterFixture("answer my emails", .email, "spec example"),
        StarterFixture("answer 47 emails", .email, "spec QA example"),
        StarterFixture("check my inbox", .email, "email"),
        StarterFixture("reply to that email", .email, "email"),

        // MARK: - Paperwork / admin / bills
        StarterFixture("pay my bills", .admin, "admin"),
        StarterFixture("do my paperwork", .admin, "admin"),
        StarterFixture("fill out the insurance form", .admin, "admin"),
        StarterFixture("renew my license at the dmv", .admin, "admin"),

        // MARK: - Taxes / finance-admin
        StarterFixture("file my taxes", .taxes, "spec example"),
        StarterFixture("do my taxes", .taxes, "taxes"),
        StarterFixture("finish my tax return", .taxes, "taxes"),

        // MARK: - Phone calls
        StarterFixture("call my dentist", .phoneCall, "phone call"),
        StarterFixture("make a phone call to mom", .phoneCall, "phone call"),
        StarterFixture("leave a voicemail for my landlord", .phoneCall, "phone call"),

        // MARK: - Workouts / gym / walking
        StarterFixture("go to the gym", .workout, "spec example"),
        StarterFixture("do a workout", .workout, "workout"),
        StarterFixture("work out", .workout, "workout"),
        StarterFixture("go for a run", .workout, "workout"),
        StarterFixture("do yoga", .workout, "workout"),
        StarterFixture("go for a walk", .workout, "walking"),
        StarterFixture("gym", .workout, "single-word short input"),

        // MARK: - Cooking / grocery shopping / errands
        StarterFixture("cook dinner", .cooking, "cooking"),
        StarterFixture("make dinner", .cooking, "cooking"),
        StarterFixture("meal prep for the week", .cooking, "cooking"),
        StarterFixture("bake a cake", .cooking, "cooking"),
        StarterFixture("go grocery shopping", .errands, "grocery shopping"),
        StarterFixture("buy groceries", .errands, "grocery shopping"),
        StarterFixture("run errands", .errands, "must not misfire as workout"),

        // MARK: - Packing / travel
        StarterFixture("pack for my trip", .packing, "packing"),
        StarterFixture("pack my suitcase", .packing, "packing"),
        StarterFixture("get ready to leave for the airport", .leavingHouse, "leaving the house"),

        // MARK: - Showering / getting dressed / personal care
        StarterFixture("take a shower", .personalCare, "showering"),
        StarterFixture("get dressed for work", .personalCare, "getting dressed"),
        StarterFixture("do my skincare routine", .personalCare, "personal care"),
        StarterFixture("brush my teeth", .personalCare, "personal care"),

        // MARK: - Organizing
        StarterFixture("organize my closet", .organizing, "organizing"),
        StarterFixture("declutter the garage", .organizing, "organizing"),
        StarterFixture("clean out my desk", .organizing, "organizing beats cleaning here"),

        // MARK: - Business / computer work
        StarterFixture("finish the quarterly report", .computerWork, "business work"),
        StarterFixture("build the slide deck", .computerWork, "computer work"),
        StarterFixture("fix the spreadsheet", .computerWork, "computer work"),
        StarterFixture("finish my coding project", .computerWork, "computer work"),

        // MARK: - Vague / slang
        StarterFixture("finish the Johnson thing", .general, "spec example — dynamic fallback"),
        StarterFixture("I need to get my shit together", .general, "spec QA example — slang"),
        StarterFixture("ugh", .general, "single vague word"),
        StarterFixture("stuff", .general, "single vague word"),
        StarterFixture("that whole thing with the apartment lease", .general, "vague, long-ish"),

        // MARK: - Typos
        StarterFixture("fiel my taxs", .taxes, "typo of file/taxes still routes"),
        StarterFixture("aparmtent is a disaster clean it", .cleaning, "typo elsewhere, clean keyword still hits"),

        // MARK: - Short inputs
        StarterFixture("help", .general, "very short, no keyword match"),
        StarterFixture("emails", .email, "single-word short input"),

        // MARK: - Long input
        StarterFixture(
            "I really need to finally organize my home office because papers taxes bills and computer cables have been piling up for literally three months and every time I sit down at my desk I just feel completely overwhelmed and end up doing anything else instead",
            .taxes,
            "long input — first keyword hit (taxes) wins deterministically"
        ),

        // MARK: - Unicode / special characters
        StarterFixture("打扫厨房", .general, "non-Latin unicode, no ascii keyword match"),
        StarterFixture("clean my kitchen 🧹✨", .cleaning, "emoji does not block keyword match"),
        StarterFixture("taxes!!!???", .taxes, "punctuation does not block keyword match"),
        StarterFixture("   go to the gym   ", .workout, "surrounding whitespace is trimmed"),
        StarterFixture("Ünïcödé tásk wíth áccénts", .general, "accented unicode, no ascii keyword match")
    ]
}
