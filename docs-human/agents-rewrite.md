Okay, I think we need to rewrite the agent role so it is something that is simple to understand.
I believe in the value of simplicity both for LLMs and for humans.
Since we are two spaces in the loop, let's make it easy on us.

I think an architecture based on perhaps more agents, but agents with shorter scripts could be useful here.
So let me scaffold something.
There are clearly several processes in creating an app.
And the main bottleneck here is when specifications aren't clear.
And there are many ways that this can happen.
This can happen by lack of definition.
Or by too much definition.
This can happen by jargon. Happens a lot.
So we must avoid those traps at all cost meaning we should speak plain english here.
A project must be somehow flexible because definition might change as the project evolves or even as before all, not only even, before all when it's first written as an MVP.

So perhaps let's isolate the specification part into several agents.
That's, I think the most important part.
The biggest problem we have is drifting.
When an agent receives less than complete specification, follow on and then passes work to the next agent and so on.
This phenomenon is called the Arabic telephone in French.
Things get passed on, they get stretched and deformed and then and so on.

So first let's get things straight.
Let's ask ourselves what defines a good spec

I think a human and an LLM way to do that would perhaps be to start from a simple idea and to iterate on that idea till we have a full, well defined, validated, technically documented solution. 
It seems to me like a process that feels natural.
Yeah, because I never like start something with a precise pick in mind. The more natural way is to start with an idea.
"I want to make X which is doing Y to Z."

So perhaps we should have agents that, or at least one agent, that's dedicated to turning that idea into...
A plan, a visual stuff of what it actually does.
A visual stuff with scenarios and at each step an assy drawing of how it renders.

Knowing also where it should render. For example, is this on a navigator? Is this on a desk app.
A CLI ?
Perhaps this could be a product vision agent.
It's right something that's almost like a doodle, I mean. A doodle, a complete doodle of the product.
This would be ASCII Visuals.

And this should be human validated.

Once we have all that clear
perhaps we can start... 
By an agent that would find the tech stack for that.
Not only find, but verify it's actually a valid way to do that.
So this agent is allowed to search the web, to compare solutions and to exchange with the human on the advantage and drawbacks of each solution.

The stack should also be human validated.


Then, enters the data-scout agent.

He's the one who will propose, he's the one who will write schemas and data contracts for the main APIs.
He's the one that should verify every external API.
If anything is wrong with what it does, the app won't just work.
For each external API we should have exactly the reply structure, the error structure clearly done.
This is written in the same document as the Doodle etc. This document serves as a single source of truth for the whole team.
So that the whole team can never lose track of what the app should be and look like.

This agent can search the web for documentation.
And should be able to do that.

Then enters the data structure verifier agent.
He is the one that will run real-life tests with all what the data scout said.
For each use case, he will have to run the stuff, run an error, run the stuff erroneously to validate or invalidate the data is good assumptions. 
If this agent validates the next step, otherwise a back and forth between the data scout and the data verifier agent.

Then and only then the app pass in the hand of the feature composer. (ex-planner)
the role of the feature composer is to check for the app spec and to get your mind what block should be built.
A block is a unit of future that can be ran and tested in isolation.
Each block will be duly tested before going to the next one.

If the project have no plan, then the planner just write a first plan of this.

If it already have plan, the planner writes what the next block should be.
The planner can also review the plan and eventually change the route of the roadmap depending on what happened before.

Then we have the coder
the coder in this version is also the test maker. 
He knows that everything should have tests and that his tests can't cheat because otherwise his work will be refused.

Then we will have the reviewer.
The reviewer checks that the coder didn't cheat his way out of the test and that the test coverage is 100%.
The reviewer also do real-life tests on the block that's just written and verifies that everything works as advised and don't throw errors.
If anything is wrong, this goes back to the coder.

And that's it, the loop is complete.

We don't have an architect, we only have an orchestrator.
The Orchestrator's role is just to determine where the project at and pass on one or other agent.
Depending of the case.

For example, if we order a new feature.
Does this feature requires a doodle or not?

And if not, it can pass this perhaps straight to the planner.
And just do a planner, coder, reviewer loop.



