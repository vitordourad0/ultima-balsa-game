local Run = {}

function Run.new()
	return {
		phase = "ready",
		checkpoint = 0,
		attempts = 0,
		startedAt = 0,
		finishedIn = 0,
		best = 0,
	}
end

function Run.restart(state)
	state.phase = "ready"
	state.checkpoint = 0
	state.startedAt = 0
	state.finishedIn = 0
end

function Run.start(state, now)
	if state.phase ~= "ready" then
		return false
	end

	state.phase = "running"
	state.startedAt = now
	state.attempts += 1
	return true
end

function Run.checkpoint(state, number)
	if state.phase ~= "running" or number ~= state.checkpoint + 1 or number > 3 then
		return false
	end

	state.checkpoint = number
	return true
end

function Run.finish(state, now)
	if state.phase ~= "running" or state.checkpoint ~= 3 or now < state.startedAt then
		return false
	end

	state.finishedIn = now - state.startedAt
	state.phase = "finished"
	if state.best == 0 or state.finishedIn < state.best then
		state.best = state.finishedIn
	end
	return true
end

return Run
