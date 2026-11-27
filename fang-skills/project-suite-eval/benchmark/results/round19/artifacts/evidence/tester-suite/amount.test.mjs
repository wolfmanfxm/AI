import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import { formatAmount } from '/Users/fangxiangming/.cache/ps-eval/round19/tester/project/src/utils/amount.ts'

describe('formatAmount', () => {
  // AC1: 输入 '.5' 应返回 '0.5'（小数必须以 0 开头）
  test('应该把 ".5" 格式化为 "0.5"', () => {
    assert.equal(formatAmount('.5'), '0.5')
  })

  // 同一 AC 家族：小数以 0 开头（负数与多位小数）
  test('应该把 "-.5" 格式化为 "-0.5"', () => {
    assert.equal(formatAmount('-.5'), '-0.5')
  })

  test('应该把 ".75" 格式化为 "0.75"', () => {
    assert.equal(formatAmount('.75'), '0.75')
  })

  // 边界：空值
  test('null 应返回空字符串', () => {
    assert.equal(formatAmount(null), '')
  })

  test('undefined 应返回空字符串', () => {
    assert.equal(formatAmount(undefined), '')
  })

  test('空字符串应返回空字符串', () => {
    assert.equal(formatAmount(''), '')
  })

  test('超长数字字符串应原样保留', () => {
    assert.equal(formatAmount('12345678901234567890'), '12345678901234567890')
  })

  // 回归：正常整数/小数不受影响
  test('应该保留 "0.5" 不变', () => {
    assert.equal(formatAmount('0.5'), '0.5')
  })

  test('应该把 "007" 规范为 "7"', () => {
    assert.equal(formatAmount('007'), '7')
  })
})
