import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import { formatAmount } from '/Users/fangxiangming/.cache/ps-eval/round19/tester/project/src/utils/amount.ts'

describe('formatAmount — AC: 小数必须以 0 开头', () => {
  // AC（唯一需求）：输入 '.5' 必须返回 '0.5'
  test('AC: ".5" -> "0.5"', () => {
    assert.equal(formatAmount('.5'), '0.5')
  })

  // 同族边界（同一规则）：负数 / 多位小数 / 超2位截断
  test('同族: "-.5" -> "-0.5"', () => {
    assert.equal(formatAmount('-.5'), '-0.5')
  })
  test('同族: ".75" -> "0.75"', () => {
    assert.equal(formatAmount('.75'), '0.75')
  })
  test('同族: ".567" -> "0.56"（先补0再保留2位）', () => {
    assert.equal(formatAmount('.567'), '0.56')
  })
})

describe('formatAmount — 边界/异常（不回归现有行为）', () => {
  test('null -> ""', () => assert.equal(formatAmount(null), ''))
  test('undefined -> ""', () => assert.equal(formatAmount(undefined), ''))
  test('"" -> ""', () => assert.equal(formatAmount(''), ''))
  test('"0.5" 原样', () => assert.equal(formatAmount('0.5'), '0.5'))
  test('"007" -> "7"', () => assert.equal(formatAmount('007'), '7'))
  test('超长输入不被截断', () =>
    assert.equal(formatAmount('12345678901234567890'), '12345678901234567890'))
})
