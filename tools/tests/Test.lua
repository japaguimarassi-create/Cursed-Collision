--!strict

local Test = {}

function Test.expect(condition: boolean, message: string)
    if not condition then
        error(message, 2)
    end
end

function Test.equal(actual, expected, message: string)
    if actual ~= expected then
        error(("%s | expected=%s actual=%s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

function Test.near(actual: number, expected: number, epsilon: number, message: string)
    if math.abs(actual - expected) > epsilon then
        error(("%s | expected=%f actual=%f"):format(message, expected, actual), 2)
    end
end

return Test
