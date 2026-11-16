import Foundation
import GraniteAgents

/// What a call answers, as `granite-answer/1`: the files written, as absolute paths, what the app calls them by, and
/// what the call made of the screens and mapping lines it was asked for.
public struct CatalogResult: AgentAnswer, Equatable {
    /// The first file written.
    public var path: String?
    /// Every file written.
    public var paths: [String]
    /// The views written, by type name.
    public var views: [String]
    /// One line a mapped type: `ModelGroup: collection`.
    public var conformances: [String]
    /// Each root view's initializer, with the app's types where a line maps them, so a page body can call it.
    public var initializers: [String]
    /// One sentence each: what the call left out or the app still has to do, and why.
    public var notes: [String]
    /// Each view and conformance written.
    public var made: [AgentMade]
    /// The views the screens asked for, and one conformance a mapping line.
    public var expected: [AgentExpected]
    /// What it could only do in part.
    public var problems: [AgentProblem]

    public init(path: String?, paths: [String], views: [String], conformances: [String], initializers: [String],
                notes: [String], made: [AgentMade] = [], expected: [AgentExpected] = [], problems: [AgentProblem] = []) {
        self.path = path; self.paths = paths; self.views = views; self.conformances = conformances
        self.initializers = initializers; self.notes = notes; self.made = made; self.expected = expected; self.problems = problems
    }
}
