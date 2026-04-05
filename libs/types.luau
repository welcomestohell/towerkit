local function nilAs<T>(): T
	return nil :: T
end

return table.freeze {
	any = nil :: any,
	nilAs = nilAs,
}
