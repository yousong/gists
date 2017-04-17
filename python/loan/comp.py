#!/usr/bin/env python
# -*-  encoding: utf-8 -*-

# 等值本息还款方式下，每月还款额
def comp_x(debt, n_month, month_rate):
    q = (1 + month_rate) ** n_month
    x = debt * month_rate * q
    x = x / (q - 1)
    return x

# 还款序列：等值本息
#
#       each_month      每月还款额，一定
#       sum_interest    总利息
#       interest        当月利息
#       each_p          当月本金
#
def comp_eq_pr(debt, n_month, month_rate):
    each_month = comp_x(debt, n_month, month_rate)
    sum_interest = 0
    while debt > 0:
        interest = debt * month_rate
        each_p = each_month - interest
        print '%9.2f %9.2f %9.2f' % (each_month, sum_interest, interest)
        sum_interest += interest
        debt -= each_p
    return sum_interest

# 还款序列：等值本金
#
#       each_month      每月还款额
#       sum_interest    总利息
#       interest        当月利息
#       each_p          当月本金，一定
#
def comp_eq_p(debt, n_month, month_rate):
    each_p = debt / n_month
    sum_interest = 0
    while debt > 0:
        interest = debt * month_rate
        each_month = each_p + interest
        print '%9.2f %9.2f %9.2f' % (each_month, sum_interest, interest)
        sum_interest += interest
        debt -= each_p
    return sum_interest

# 公基金贷款利率：5年为分界
def comp_month_rate_cpf(n_month):
    if n_month <= 60:
        return 2.75 / 100 / 12
    else:
        return 3.25 / 100 / 12

debt = 300000

n_month = 120
month_rate = comp_month_rate_cpf(n_month)

#comp_eq_pr(debt, n_month, month_rate)
comp_eq_p(debt, n_month, month_rate)
