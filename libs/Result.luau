local repr = require("./repr")
local Result = {}
Result.__index = Result

export type Result<T, E> = setmetatable<{ read kind: "Ok" | "Err", read value: T | E }, typeof(Result)>

function Result.Ok<T>(value: T): Result<T, any>
	return table.freeze(setmetatable({ kind = "Ok" :: "Ok", value = value }, Result))
end

function Result.Err<E>(value: E): Result<any, E>
	return table.freeze(setmetatable({ kind = "Err" :: "Err", value = value }, Result))
end

function Result.isResult(x: any)
	return typeof(x) == "table" and getmetatable(x) == Result
end

function Result.isOk(self: Result<any, any>)
	return self.kind == "Ok"
end

function Result.isErr(self: Result<any, any>)
	return self.kind == "Err"
end

function Result.expect<T>(self: Result<T, any>, message: string): T
	return if Result.isOk(self) then self.value else error(message, 2)
end

function Result.expectErr<E>(self: Result<any, E>, message: string): E
	return if Result.isErr(self) then self.value else error(message, 2)
end

function Result.unwrap<T>(self: Result<T, any>): T
	return if Result.isOk(self) then self.value else error(self.value, 2)
end

function Result.unwrapErr<E>(self: Result<any, E>): E
	return if Result.isErr(self) then self.value else error(self.value, 2)
end

function Result.match<T, E, R>(
	self: Result<T, E>,
	branches: {
		read Ok: (T) -> R,
		read Err: (E) -> R,
	}
): R
	return (if Result.isOk(self) then branches.Ok else branches.Err)(self.value)
end

function Result.__tostring(self: Result<any, any>): string
	return if self:isOk() then `Result.Ok({repr(self.value)})` else `Result.Err({repr(self.value)})`
end

return table.freeze(Result)
