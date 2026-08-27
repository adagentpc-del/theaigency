import Foundation

/// One variant within a category's starter-action set: a primary tiny step,
/// its reassurance line, and its own chain of further reductions for
/// "Make it even smaller".
struct StarterEntry: Equatable {
    let primary: String
    let reassurance: String
    let reductions: [String]
}

/// The hand-authored library of tiny first actions, grouped by category.
///
/// `entries[category].first` is always the canonical, spec-verified action
/// for that category (what a first-time user sees). The rest of the array is
/// used for "Give me a different start" so repeat taps don't loop the same
/// suggestion back immediately.
enum StarterActionLibrary {
    static let entries: [TaskCategory: [StarterEntry]] = [
        .cleaning: [
            StarterEntry(
                primary: "Throw away one piece of trash.",
                reassurance: "You do not have to clean the whole place yet.",
                reductions: ["Pick up one piece of trash. You don't have to throw it away yet.", "Stand up."]
            ),
            StarterEntry(
                primary: "Pick up one thing that doesn't belong there.",
                reassurance: "Just the one thing.",
                reductions: ["Look around and find one thing that's out of place.", "Stand up."]
            ),
            StarterEntry(
                primary: "Put one item back where it belongs.",
                reassurance: "One item. That's the whole job right now.",
                reductions: ["Pick up one item.", "Stand up."]
            ),
            StarterEntry(
                primary: "Walk to the room. Don't clean yet.",
                reassurance: "Just walk there. Nothing else.",
                reductions: ["Stand up and take one step toward the room."]
            )
        ],
        .laundry: [
            StarterEntry(
                primary: "Put the laundry basket where you can reach it.",
                reassurance: "You don't have to start a load yet.",
                reductions: ["Walk to where the basket is.", "Stand up."]
            ),
            StarterEntry(
                primary: "Pick up one piece of clothing.",
                reassurance: "Just the one piece.",
                reductions: ["Look at the pile. Point to one piece.", "Stand up."]
            ),
            StarterEntry(
                primary: "Put one item in the washer.",
                reassurance: "One item counts.",
                reductions: ["Carry one item toward the washer.", "Stand up."]
            ),
            StarterEntry(
                primary: "Carry the basket to the machine.",
                reassurance: "You don't have to sort anything yet.",
                reductions: ["Pick up the basket.", "Stand up."]
            )
        ],
        .dishes: [
            StarterEntry(
                primary: "Put one dish in the sink.",
                reassurance: "You don't have to wash anything yet.",
                reductions: ["Pick up one dish.", "Stand up and walk to the kitchen."]
            ),
            StarterEntry(
                primary: "Run the water and rinse one dish.",
                reassurance: "Just the one.",
                reductions: ["Turn the water on.", "Walk to the sink."]
            ),
            StarterEntry(
                primary: "Clear one item off the counter.",
                reassurance: "One item counts.",
                reductions: ["Pick up one item near the sink.", "Walk to the kitchen."]
            ),
            StarterEntry(
                primary: "Load one dish into the dishwasher.",
                reassurance: "You don't have to load the rest yet.",
                reductions: ["Open the dishwasher.", "Walk to the kitchen."]
            )
        ],
        .studying: [
            StarterEntry(
                primary: "Open the material.",
                reassurance: "You don't have to read it yet.",
                reductions: ["Put your hand on the book or laptop.", "Sit down at your desk."]
            ),
            StarterEntry(
                primary: "Put the notebook or book in front of you.",
                reassurance: "Just put it there.",
                reductions: ["Find the notebook or book.", "Sit down."]
            ),
            StarterEntry(
                primary: "Read the first heading.",
                reassurance: "Just the heading. Nothing else.",
                reductions: ["Open to any page.", "Open the material."]
            ),
            StarterEntry(
                primary: "Write the topic at the top of a page.",
                reassurance: "One line. That's it.",
                reductions: ["Pick up a pen.", "Sit down at your desk."]
            )
        ],
        .writing: [
            StarterEntry(
                primary: "Open the document.",
                reassurance: "You don't have to write anything yet.",
                reductions: ["Open your laptop.", "Sit down."]
            ),
            StarterEntry(
                primary: "Write one sentence, even a bad one.",
                reassurance: "It doesn't have to be good.",
                reductions: ["Open the document.", "Open your laptop."]
            ),
            StarterEntry(
                primary: "Write the title at the top.",
                reassurance: "Just the title.",
                reductions: ["Open the document.", "Open your laptop."]
            ),
            StarterEntry(
                primary: "Open a blank page and put today's date on it.",
                reassurance: "That's the whole job right now.",
                reductions: ["Open your laptop."]
            )
        ],
        .email: [
            StarterEntry(
                primary: "Open your inbox.",
                reassurance: "You don't have to answer anything yet.",
                reductions: ["Unlock your phone or computer.", "Pick up your phone."]
            ),
            StarterEntry(
                primary: "Find the message you most need to answer.",
                reassurance: "You don't have to reply yet.",
                reductions: ["Open your inbox.", "Unlock your phone."]
            ),
            StarterEntry(
                primary: "Open the document you need.",
                reassurance: "Just open it.",
                reductions: ["Unlock your phone or computer."]
            ),
            StarterEntry(
                primary: "Put the relevant tab on screen.",
                reassurance: "That's the whole job right now.",
                reductions: ["Unlock your phone or computer."]
            )
        ],
        .admin: [
            StarterEntry(
                primary: "Open the form or document you need.",
                reassurance: "You don't have to fill it out yet.",
                reductions: ["Find where the form is.", "Sit down at your desk."]
            ),
            StarterEntry(
                primary: "Put the paperwork in one pile in front of you.",
                reassurance: "Just gather it.",
                reductions: ["Find one piece of paperwork.", "Walk to where it is."]
            ),
            StarterEntry(
                primary: "Open the bill or statement.",
                reassurance: "You don't have to pay it yet.",
                reductions: ["Find the bill.", "Sit down."]
            ),
            StarterEntry(
                primary: "Write down what the task actually is.",
                reassurance: "One line is enough.",
                reductions: ["Pick up a pen or your phone."]
            )
        ],
        .taxes: [
            StarterEntry(
                primary: "Open the website or folder you use for your taxes.",
                reassurance: "You don't have to enter anything yet.",
                reductions: ["Find the login or the folder.", "Sit down at your desk."]
            ),
            StarterEntry(
                primary: "Find one document you'll need.",
                reassurance: "Just the one.",
                reductions: ["Open the drawer or folder where tax stuff lives.", "Sit down."]
            ),
            StarterEntry(
                primary: "Open last year's return for reference.",
                reassurance: "You're just looking, not filing.",
                reductions: ["Find where it's saved."]
            ),
            StarterEntry(
                primary: "Put your laptop in front of you and open the tax site.",
                reassurance: "That's the whole job right now.",
                reductions: ["Sit down at your desk."]
            )
        ],
        .workout: [
            StarterEntry(
                primary: "Put your shoes on.",
                reassurance: "You do not have to go to the gym yet.",
                reductions: ["Put one shoe next to your foot.", "Stand up."]
            ),
            StarterEntry(
                primary: "Change into workout clothes.",
                reassurance: "That's the whole job right now.",
                reductions: ["Pick up one piece of workout clothing.", "Stand up."]
            ),
            StarterEntry(
                primary: "Fill your water bottle.",
                reassurance: "You don't have to work out yet.",
                reductions: ["Pick up the water bottle.", "Walk to the kitchen."]
            ),
            StarterEntry(
                primary: "Stand up and move toward where you'll start.",
                reassurance: "Just move that direction.",
                reductions: ["Stand up."]
            )
        ],
        .leavingHouse: [
            StarterEntry(
                primary: "Put your shoes by the door.",
                reassurance: "You don't have to leave yet.",
                reductions: ["Find your shoes.", "Stand up."]
            ),
            StarterEntry(
                primary: "Find your keys.",
                reassurance: "Just find them.",
                reductions: ["Check the usual spot.", "Stand up."]
            ),
            StarterEntry(
                primary: "Put on one thing you'll need to leave.",
                reassurance: "One item counts.",
                reductions: ["Pick up one item you'll need.", "Stand up."]
            ),
            StarterEntry(
                primary: "Walk to the door. Don't leave yet.",
                reassurance: "Just walk there.",
                reductions: ["Stand up."]
            )
        ],
        .packing: [
            StarterEntry(
                primary: "Put your bag or suitcase where you can reach it.",
                reassurance: "You don't have to pack it yet.",
                reductions: ["Find the bag.", "Stand up."]
            ),
            StarterEntry(
                primary: "Put one item into the bag.",
                reassurance: "One item counts.",
                reductions: ["Pick up one item you'll need.", "Stand up."]
            ),
            StarterEntry(
                primary: "Open the drawer or closet you need.",
                reassurance: "Just open it.",
                reductions: ["Walk to the closet.", "Stand up."]
            ),
            StarterEntry(
                primary: "Make a short list of three things you can't forget.",
                reassurance: "Three items. That's it.",
                reductions: ["Pick up a pen or your phone."]
            )
        ],
        .cooking: [
            StarterEntry(
                primary: "Take out one ingredient.",
                reassurance: "You don't have to start cooking yet.",
                reductions: ["Open the fridge or pantry.", "Walk to the kitchen."]
            ),
            StarterEntry(
                primary: "Fill a pot with water.",
                reassurance: "That's the whole job right now.",
                reductions: ["Walk to the sink.", "Walk to the kitchen."]
            ),
            StarterEntry(
                primary: "Put one pan on the stove.",
                reassurance: "You don't have to turn it on yet.",
                reductions: ["Open the cabinet.", "Walk to the kitchen."]
            ),
            StarterEntry(
                primary: "Decide what you're making. Just decide.",
                reassurance: "Nothing else yet.",
                reductions: ["Walk to the kitchen."]
            )
        ],
        .errands: [
            StarterEntry(
                primary: "Make a list of the one or two things you actually need.",
                reassurance: "You don't have to leave yet.",
                reductions: ["Pick up your phone or a pen.", "Sit down for a second."]
            ),
            StarterEntry(
                primary: "Find your keys and wallet.",
                reassurance: "Just find them.",
                reductions: ["Check the usual spot.", "Stand up."]
            ),
            StarterEntry(
                primary: "Put your shoes on.",
                reassurance: "You don't have to drive there yet.",
                reductions: ["Find your shoes.", "Stand up."]
            ),
            StarterEntry(
                primary: "Open the store's app or website to check hours.",
                reassurance: "That's the whole job right now.",
                reductions: ["Unlock your phone."]
            )
        ],
        .phoneCall: [
            StarterEntry(
                primary: "Find the phone number.",
                reassurance: "You don't have to dial yet.",
                reductions: ["Open your contacts or the message it's in.", "Pick up your phone."]
            ),
            StarterEntry(
                primary: "Open the contact.",
                reassurance: "Just open it.",
                reductions: ["Pick up your phone."]
            ),
            StarterEntry(
                primary: "Write the first sentence you need to say.",
                reassurance: "One sentence. That's it.",
                reductions: ["Pick up your phone or a pen."]
            ),
            StarterEntry(
                primary: "Put your phone in your hand.",
                reassurance: "You don't have to call yet.",
                reductions: ["Find your phone."]
            )
        ],
        .organizing: [
            StarterEntry(
                primary: "Open the drawer, closet, or space you need.",
                reassurance: "You don't have to organize it all yet.",
                reductions: ["Walk to the space.", "Stand up."]
            ),
            StarterEntry(
                primary: "Pick up one item that needs a home.",
                reassurance: "One item counts.",
                reductions: ["Look at the pile.", "Stand up."]
            ),
            StarterEntry(
                primary: "Clear one small surface.",
                reassurance: "Just the one surface.",
                reductions: ["Pick up one item off it.", "Stand up."]
            ),
            StarterEntry(
                primary: "Make one pile: keep or go.",
                reassurance: "One decision at a time.",
                reductions: ["Pick up one item."]
            )
        ],
        .computerWork: [
            StarterEntry(
                primary: "Open the file or project.",
                reassurance: "You don't have to finish it yet.",
                reductions: ["Open your laptop.", "Sit down at your desk."]
            ),
            StarterEntry(
                primary: "Put the document on screen.",
                reassurance: "Just open it.",
                reductions: ["Open your laptop."]
            ),
            StarterEntry(
                primary: "Write one line, even a rough one.",
                reassurance: "It doesn't have to be right.",
                reductions: ["Open the file.", "Open your laptop."]
            ),
            StarterEntry(
                primary: "Open your notes for this project.",
                reassurance: "That's the whole job right now.",
                reductions: ["Sit down at your desk."]
            )
        ],
        .personalCare: [
            StarterEntry(
                primary: "Walk to the bathroom.",
                reassurance: "You don't have to shower yet.",
                reductions: ["Stand up."]
            ),
            StarterEntry(
                primary: "Turn the water on.",
                reassurance: "Just turn it on.",
                reductions: ["Walk to the bathroom.", "Stand up."]
            ),
            StarterEntry(
                primary: "Pick up your toothbrush.",
                reassurance: "That's the whole job right now.",
                reductions: ["Walk to the sink.", "Stand up."]
            ),
            StarterEntry(
                primary: "Pick out one thing to wear.",
                reassurance: "One item. That's it.",
                reductions: ["Open the closet.", "Stand up."]
            )
        ],
        .general: [
            StarterEntry(
                primary: "Open the thing you need.",
                reassurance: "You don't have to finish it yet.",
                reductions: ["Find where it is.", "Stand up."]
            ),
            StarterEntry(
                primary: "Put what you need in front of you.",
                reassurance: "Just get it in front of you.",
                reductions: ["Find it.", "Stand up."]
            ),
            StarterEntry(
                primary: "Stand up and move toward where the task happens.",
                reassurance: "Just move that direction.",
                reductions: ["Stand up."]
            ),
            StarterEntry(
                primary: "Do the smallest visible piece.",
                reassurance: "The smallest piece counts.",
                reductions: ["Look at it for ten seconds.", "Walk toward it."]
            )
        ]
    ]
}
