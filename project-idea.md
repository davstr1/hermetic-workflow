I want to build the hermetic workflow.

It's a claude code tdd workflow.
Aims to be relatively lightweight yet very efficient.

First, the tasks are given two a tests making agent

then and only then the coding agent intervene.

After that, time for the reviewing agent to review the work of the coding agent.
Against the project principles which are in a MD file.

When the review pass : 
the reviewing agent commits the change.
Next task
if the review don't pass, bask back to the coding agent with an explanation from the reviewing agent.

Everything inside a Ralph Wiggum Loop.

About from that, rules are also enforced by a set of eslint rules, such as in @example-ui-rules/

but the main twist of this workflow is the following.

Coding agent absolutely can't see the rules themselves. Nor can it see it and even edit it.
Those rules must clearly be out of its reach. This must not be an advice in an MD file this must be an enforcement.

The way to do that is to perhaps make those rules clearly out of his reach by schmoding them or something like that. I'm not sure. Or perhaps just put them in a folder that he can't access. or not even see.

So instead you have a pre-tool use hook on cre and creating modifying files that automatically execute those rules.

The coding agent also must not be able to see the The tests.

The coding agent should also not be able to corrupt the reviewing agent or The test maker agent.

This is for JS/ node projects this should be agnostic of React, etc. Or perhaps we can create a set of rules for each technology.

That's it. What do you think of this workflow and how it can be done?











