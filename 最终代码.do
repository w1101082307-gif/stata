version 18.0
clear all
set more off
set seed 20261102
use "datanew1.dta", clear
isid stkcd year
assert inrange(year, 2010, 2024)
assert _N == 23203
xtset stkcd year
capture drop Fin_Total Fin_Total_cash
gen double Fin_Total      = Fin_Short + Fin_Long
gen double Fin_Total_cash = Fin_Total + Cash
label var Fin_Total      "金融化总量=短期+长期"
label var Fin_Total_cash "金融化总量+货币资金"
capture confirm variable CCI_strict
if _rc {
    gen double CCI_strict = CRI_strict - TRI_v2 - SSI_strict
    replace CCI_strict = 0 if abs(CCI_strict) < 1e-12
}
global controls Size Lev ROA Growth CashFlow Fixed Dual Top1 ListAge SOE
**描述性统计与相关系数
tabstat Fin_Total Fin_Short Fin_Long Cash Size Lev ROA Growth CashFlow ///
    Fixed Dual Top1 ListAge SOE TRI SSI CCI CRI, ///
    statistics(n mean sd p25 p50 p75 min max) columns(statistics)
pwcorr Fin_Total Fin_Short Fin_Long Cash TRI SSI CCI CRI, sig star(.05)

**基准回归
reghdfe Fin_Total CRI, absorb(stkcd year) vce(cluster stkcd)
reghdfe Fin_Total CRI $controls, absorb(stkcd year) vce(cluster stkcd)
reghdfe Fin_Total TRI SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
reghdfe Fin_Short TRI SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
reghdfe Fin_Long TRI SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)


**内生性
capture drop sample_ivtri1 sample_ivssi1  nmiss_ivtri1 nmiss_ivssi1
* TRI工具变量样本：只保留2017年低碳城市试点和从未试点城市
egen int nmiss_ivtri1 = rowmiss(Fin_Long TRI SSI CCI z_lc17 cc $controls)
gen byte sample_ivtri1 =  (missing(lc_year) | lc_year == 2017) & nmiss_ivtri1 == 0
drop nmiss_ivtri1
* SSI工具变量样本：只保留2015年首批海绵城市和从未试点城市
egen int nmiss_ivssi1 = rowmiss(Fin_Short SSI TRI CCI  z_sponge15 cc $controls)
gen byte sample_ivssi1 =  (missing(sponge_year) | sponge_year == 2015) & nmiss_ivssi1 == 0
drop nmiss_ivssi1
tab sample_ivtri1
tab sample_ivssi1
capture drop rel_lc17 lc17_m4 lc17_m3 lc17_m2 lc17_0 lc17_p1 lc17_p2 lc17_p3 lc17_p4 lc17_p5
gen int rel_lc17 = year - lc_year if lc_year == 2017
foreach var in lc17_m4 lc17_m3 lc17_m2 lc17_0 lc17_p1 lc17_p2 lc17_p3 lc17_p4 lc17_p5 {
    gen byte `var' = 0
}
* 政策前4期及更早合并为一个时期
replace lc17_m4 = 1 if lc_year == 2017 &  rel_lc17 <= -4 & !missing(rel_lc17)
replace lc17_m3 = 1 if lc_year == 2017 & rel_lc17 == -3
replace lc17_m2 = 1 if lc_year == 2017 & rel_lc17 == -2
* rel_lc17=-1，即2016年，为省略的基准期
replace lc17_0  = 1 if lc_year == 2017 & rel_lc17 == 0
replace lc17_p1 = 1 if lc_year == 2017 & rel_lc17 == 1
replace lc17_p2 = 1 if lc_year == 2017 & rel_lc17 == 2
replace lc17_p3 = 1 if lc_year == 2017 & rel_lc17 == 3
replace lc17_p4 = 1 if lc_year == 2017 & rel_lc17 == 4
* 政策后5期及以后合并
replace lc17_p5 = 1 if lc_year == 2017 &  rel_lc17 >= 5 & !missing(rel_lc17)
capture drop rel_sp15 sp15_m4 sp15_m3 sp15_m2 sp15_0 sp15_p1 sp15_p2 sp15_p3 sp15_p4 sp15_p5
gen int rel_sp15 = year - sponge_year if sponge_year == 2015
foreach var in sp15_m4 sp15_m3 sp15_m2 ///
    sp15_0 sp15_p1 sp15_p2 sp15_p3 sp15_p4 sp15_p5 {
    gen byte `var' = 0
}
* 政策前4期及更早合并为一个时期
replace sp15_m4 = 1 if sponge_year == 2015 & rel_sp15 <= -4 & !missing(rel_sp15)
replace sp15_m3 = 1 if sponge_year == 2015 & rel_sp15 == -3
replace sp15_m2 = 1 if sponge_year == 2015 & rel_sp15 == -2
* rel_sp15=-1，即2014年，为省略的基准期
replace sp15_0  = 1 if sponge_year == 2015 & rel_sp15 == 0
replace sp15_p1 = 1 if sponge_year == 2015 & rel_sp15 == 1
replace sp15_p2 = 1 if sponge_year == 2015 & rel_sp15 == 2
replace sp15_p3 = 1 if sponge_year == 2015 & rel_sp15 == 3
replace sp15_p4 = 1 if sponge_year == 2015 & rel_sp15 == 4
* 政策后5期及以后合并
replace sp15_p5 = 1 if sponge_year == 2015 & rel_sp15 >= 5 & !missing(rel_sp15)
* 1. TRI工具变量：2017年低碳城市试点
reghdfe TRI z_lc17 SSI CCI $controls if sample_ivtri1 == 1, ///
    absorb(stkcd year) vce(cluster cc)
test z_lc17
ivreghdfe Fin_Long SSI CCI $controls (TRI = z_lc17) ///
    if sample_ivtri1 == 1 , absorb(stkcd year) cluster(cc) first
* 2. SSI工具变量：2015年首批海绵城市试点
reghdfe SSI z_sponge15 TRI CCI $controls if sample_ivssi1 == 1, ///
    absorb(stkcd year) vce(cluster cc)
test z_sponge15
ivreghdfe Fin_Short TRI CCI $controls (SSI = z_sponge15) ///
    if sample_ivssi1 == 1  , absorb(stkcd year) cluster(cc) first
* 3. 政策实施前趋势
reghdfe TRI  lc17_m4 lc17_m3 lc17_m2 lc17_0 lc17_p1 lc17_p2 lc17_p3 lc17_p4 lc17_p5 $controls if sample_ivtri1 == 1, absorb(stkcd year) vce(cluster cc)
test  lc17_m4 lc17_m3 lc17_m2
test lc17_0 lc17_p1 lc17_p2 lc17_p3 lc17_p4 lc17_p5
reghdfe SSI  sp15_m4 sp15_m3 sp15_m2 sp15_0 sp15_p1 sp15_p2 sp15_p3 sp15_p4 sp15_p5 $controls if sample_ivssi1 == 1, absorb(stkcd year) vce(cluster cc)
test  sp15_m4 sp15_m3 sp15_m2
test sp15_0 sp15_p1 sp15_p2 sp15_p3 sp15_p4 sp15_p5
* 5. Oster遗漏变量敏感性
xtreg Fin_Long TRI SSI CCI $controls i.year, fe vce(cluster stkcd)
local rmax_tri = min(1, 1.3*e(r2_w))
psacalc delta TRI, rmax(`rmax_tri')
xtreg Fin_Short SSI TRI CCI $controls i.year, fe vce(cluster stkcd)
local rmax_ssi = min(1, 1.3*e(r2_w))
psacalc delta SSI, rmax(`rmax_ssi')


**机制检验
capture drop GreenInv_M GreenUma_M CreditAccess InterestBurden ///
    M_green_t1 M_greenuma_t1 M_credit_t1 M_interest_t1 ///
    Y_long_t2 Y_short_t2
* 绿色发明专利申请量：ln(1+绿色发明专利申请数)
gen double GreenInv_M = ln(1 + Green_Inv) if Green_Inv >= 0 & !missing(Green_Inv)
* 绿色实用新型专利申请量：作为绿色创新机制的替代指标
gen double GreenUma_M = ln(1 + Green_Uma) if Green_Uma >= 0 & !missing(Green_Uma)
* 信贷可得性：信用借款占比原始单位为百分比，转换为0—1比例
gen double CreditAccess = credit_ratio / 100 ///
    if inrange(credit_ratio, 0, 100)
* 利息负担：利息支出/总资产；IntExp已在数据清洗阶段计算
gen double InterestBurden = IntExp if IntExp >= 0 & !missing(IntExp)
* 对新构造的连续机制变量按年度缩尾
winsor2 GreenInv_M GreenUma_M CreditAccess InterestBurden, ///
    replace cuts(1 99) by(year)
* 时序安排：t期气候风险→t+1期机制变量→t+2期金融资产配置
gen double M_green_t1    = F.GreenInv_M
gen double M_greenuma_t1 = F.GreenUma_M
gen double M_credit_t1   = F.CreditAccess
gen double M_interest_t1 = F.InterestBurden
gen double Y_long_t2  = F2.Fin_Long
gen double Y_short_t2 = F2.Fin_Short
label var M_green_t1    "下一期绿色发明专利"
label var M_greenuma_t1 "下一期绿色实用新型专利"
label var M_credit_t1   "下一期信贷可得性"
label var M_interest_t1 "下一期利息负担"
label var Y_long_t2     "两期后长期金融化"
label var Y_short_t2    "两期后短期金融化"
quietly reghdfe Y_long_t2 M_green_t1 M_greenuma_t1 TRI SSI CCI ///
    $controls, absorb(stkcd year) vce(cluster stkcd)
gen byte sample_med_green = e(sample)
* 融资机制共同样本
quietly reghdfe Y_short_t2 M_credit_t1 M_interest_t1 SSI TRI CCI ///
    $controls, absorb(stkcd year) vce(cluster stkcd)
gen byte sample_med_fin = e(sample)
tab sample_med_green
tab sample_med_fin
**绿色创新机制
*F1：同一机制样本中的总效应
reghdfe Y_long_t2 TRI SSI CCI $controls if sample_med_green == 1, ///
    absorb(stkcd year) vce(cluster stkcd)
* F2：转型风险对绿色发明创新的影响
reghdfe M_green_t1 TRI SSI CCI $controls if sample_med_green == 1, ///
    absorb(stkcd year) vce(cluster stkcd)
* F3：绿色发明创新的机制路径
reghdfe Y_long_t2 M_green_t1 TRI SSI CCI $controls if sample_med_green == 1, absorb(stkcd year) vce(cluster stkcd)
* F4：绿色实用新型专利替代指标
reghdfe M_greenuma_t1 TRI SSI CCI $controls if sample_med_green == 1,  absorb(stkcd year) vce(cluster stkcd)
* F5：绿色实用新型专利替代机制
reghdfe Y_long_t2 M_greenuma_t1 TRI SSI CCI $controls  if sample_med_green == 1, absorb(stkcd year) vce(cluster stkcd)

**绿色创新间接效应 Bootstrap
isid stkcd year
capture program drop med_green
capture drop bs_id
program define med_green, rclass
    quietly reghdfe M_green_t1 TRI SSI CCI Size Lev ROA Growth ///
        CashFlow Fixed Dual Top1 ListAge ///
        if sample_med_green == 1, absorb(bs_id year)
    local a = _b[TRI]
    quietly reghdfe Y_long_t2 M_green_t1 TRI SSI CCI Size Lev ROA ///
        Growth CashFlow Fixed Dual Top1 ListAge ///
        if sample_med_green == 1, absorb(bs_id year)
    return scalar indirect = `a' * _b[M_green_t1]
end
* 清除原来的xtset设置，防止企业被重复抽中后出现重复时间值
xtset, clear
* 正式复现默认1000次；运行do文件时可传入较小次数进行快速检查。
bootstrap indirect=r(indirect) if sample_med_green == 1, ///
    reps(1000) cluster(stkcd) idcluster(bs_id) ///
    seed(20261104) nodots: med_green
estat bootstrap, all
* Bootstrap完成后恢复原面板设置
xtset stkcd year

**融资机制
* F6：同一机制样本中的总效应
reghdfe Y_short_t2 SSI TRI CCI $controls if sample_med_fin == 1, ///
    absorb(stkcd year) vce(cluster stkcd)
* F7：信贷可得性路径
reghdfe M_credit_t1 SSI TRI CCI $controls if sample_med_fin == 1 , ///
    absorb(stkcd year) vce(cluster stkcd)
* F8：利息负担路径
reghdfe M_interest_t1 SSI TRI CCI $controls if sample_med_fin == 1, ///
    absorb(stkcd year) vce(cluster stkcd)
* F9：两个融资渠道同时进入
reghdfe Y_short_t2 M_credit_t1 M_interest_t1 SSI TRI CCI $controls ///
    if sample_med_fin == 1, absorb(stkcd year) vce(cluster stkcd)

**融资机制间接效应 Bootstrap
capture program drop med_finance
capture drop bs_id
program define med_finance, rclass
    quietly reghdfe M_credit_t1 SSI TRI CCI Size Lev ROA Growth ///
        CashFlow Fixed Dual Top1 ListAge ///
        if sample_med_fin == 1, absorb(bs_id year)
    local ac = _b[SSI]
    quietly reghdfe M_interest_t1 SSI TRI CCI Size Lev ROA Growth ///
        CashFlow Fixed Dual Top1 ListAge ///
        if sample_med_fin == 1, absorb(bs_id year)
    local ai = _b[SSI]
    quietly reghdfe Y_short_t2 M_credit_t1 M_interest_t1 ///
        SSI TRI CCI Size Lev ROA Growth CashFlow Fixed Dual ///
        Top1 ListAge if sample_med_fin == 1, absorb(bs_id year)
    return scalar indirect_credit   = `ac' * _b[M_credit_t1]
    return scalar indirect_interest = `ai' * _b[M_interest_t1]
end
xtset, clear
bootstrap credit=r(indirect_credit) interest=r(indirect_interest) ///
    if sample_med_fin == 1, reps(1000) cluster(stkcd) ///
    idcluster(bs_id) seed(20261105) nodots: med_finance
estat bootstrap, all
xtset stkcd year


**异质性
capture drop HSOE HCarbon insample
* 所有制：1=国有企业，0=非国有企业
gen byte HSOE = SOE if inlist(SOE, 0, 1)
label var HSOE "国有企业"
* 高碳行业：根据现有行业分类重新构造
gen byte HCarbon = 0 if trim(indcode) != ""
foreach c in B06 B07 B08 B09 C17 C19 C22 C25 C26 C28 C29 C30 C31 C32 D44 {
    replace HCarbon = 1 if substr(indcode, 1, 3) == "`c'"
}
label var HCarbon "高碳行业"
tab HSOE, missing
tab HCarbon, missing
* 用包含全部异质性变量的最大模型确定共同样本
 reghdfe Fin_Long c.TRI##i.HSOE c.SSI##i.HSOE ///
    c.TRI##i.HCarbon c.SSI##i.HCarbon CCI $controls ///
    if !missing(Fin_Short), absorb(stkcd year) vce(cluster stkcd)
* 7.1 所有制异质性
* G1：转型风险对长期金融化的所有制异质性
reghdfe Fin_Long c.TRI##i.HSOE SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
* 正式检验国企与非国企的TRI系数是否存在显著差异
test 1.HSOE#c.TRI = 0
* 计算国有企业中的TRI总效应
lincom TRI + 1.HSOE#c.TRI
* G2：急性物理风险对短期金融化的所有制异质性
reghdfe Fin_Short c.SSI##i.HSOE TRI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
* 正式检验国企与非国企的SSI系数差异
test 1.HSOE#c.SSI = 0
* 计算国有企业中的SSI总效应
lincom SSI + 1.HSOE#c.SSI
* 7.2 高碳行业异质性
* G3：转型风险对长期金融化的行业异质性
reghdfe Fin_Long c.TRI##i.HCarbon SSI CCI $controls,  absorb(stkcd year) vce(cluster stkcd)
* 正式检验高碳行业与非高碳行业的TRI系数差异
test 1.HCarbon#c.TRI = 0
* 计算高碳行业中的TRI总效应
lincom TRI + 1.HCarbon#c.TRI
* G4：急性物理风险对短期金融化的行业异质性
reghdfe Fin_Short c.SSI##i.HCarbon TRI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
* 正式检验高碳行业与非高碳行业的SSI系数差异
test 1.HCarbon#c.SSI = 0
* 计算高碳行业中的SSI总效应
lincom SSI + 1.HCarbon#c.SSI

**稳健性
capture drop ind_year_rob sample_rob_lag sample_rob_ind ///
    sample_rob_covid sample_rob_fd
* 行业×年份固定效应
egen long ind_year_rob = group(indcode year)
* 一阶差分变量
foreach var in Fin_Long Fin_Short TRI SSI CCI Size Lev ROA Growth ///
    CashFlow Fixed Dual Top1 ListAge {
    capture drop d_`var'
    gen double d_`var' = D.`var'
}
* 滞后一期检验的共同样本
quietly reghdfe Fin_Long L.TRI L.SSI L.CCI $controls ///
    if !missing(Fin_Short), absorb(stkcd year) vce(cluster stkcd)
gen byte sample_rob_lag = e(sample)
* 行业×年份固定效应检验的共同样本
quietly reghdfe Fin_Long TRI SSI CCI $controls ///
    if !missing(Fin_Short), absorb(stkcd ind_year_rob) vce(cluster stkcd)
gen byte sample_rob_ind = e(sample)
* 剔除2020—2022年的共同样本
quietly reghdfe Fin_Long TRI SSI CCI $controls ///
    if !inrange(year, 2020, 2022) & !missing(Fin_Short), ///
    absorb(stkcd year) vce(cluster stkcd)
gen byte sample_rob_covid = e(sample)
* 一阶差分检验的共同样本
quietly reghdfe d_Fin_Long d_TRI d_SSI d_CCI d_Size d_Lev d_ROA ///
    d_Growth d_CashFlow d_Fixed d_Dual d_Top1 d_ListAge ///
    if !missing(d_Fin_Short), absorb(year) vce(cluster stkcd)
gen byte sample_rob_fd = e(sample)
tab sample_rob_lag
tab sample_rob_ind
tab sample_rob_covid
tab sample_rob_fd
* R1：转型风险与长期金融化
reghdfe Fin_Long L.TRI L.SSI L.CCI $controls ///
    if sample_rob_lag == 1, absorb(stkcd year) vce(cluster stkcd)
* R2：急性物理风险与短期金融化
reghdfe Fin_Short L.TRI L.SSI L.CCI $controls ///
    if sample_rob_lag == 1, absorb(stkcd year) vce(cluster stkcd)
* R3：转型风险与长期金融化
reghdfe Fin_Long TRI SSI CCI $controls if sample_rob_ind == 1, ///
    absorb(stkcd ind_year_rob) vce(cluster stkcd)
* R4：急性物理风险与短期金融化
reghdfe Fin_Short TRI SSI CCI $controls if sample_rob_ind == 1, ///
    absorb(stkcd ind_year_rob) vce(cluster stkcd)
* R5：转型风险与长期金融化
reghdfe Fin_Long TRI SSI CCI $controls if sample_rob_covid == 1, ///
    absorb(stkcd year) vce(cluster stkcd)

* R6：急性物理风险与短期金融化
reghdfe Fin_Short TRI SSI CCI $controls if sample_rob_covid == 1, ///
    absorb(stkcd year) vce(cluster stkcd)
* R7：转型风险变化与长期金融化变化
reghdfe d_Fin_Long d_TRI d_SSI d_CCI d_Size d_Lev d_ROA ///
    d_Growth d_CashFlow d_Fixed d_Dual d_Top1 d_ListAge ///
    if sample_rob_fd == 1, absorb(year) vce(cluster stkcd)
* R8：急性物理风险变化与短期金融化变化
reghdfe d_Fin_Short d_TRI d_SSI d_CCI d_Size d_Lev d_ROA ///
    d_Growth d_CashFlow d_Fixed d_Dual d_Top1 d_ListAge ///
    if sample_rob_fd == 1, absorb(year) vce(cluster stkcd)

**替代指标与口径检验
* 替代金融化定义
reghdfe Fin_Total_2018old TRI SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
reghdfe Fin_Total_2018new TRI SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
reghdfe Fin_Total_adj TRI SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
reghdfe Fin_Obj TRI SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
reghdfe Fin_Broad TRI SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
* 期限结构与函数形式替代指标
reghdfe Fin_Short2 TRI SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
reghdfe Fin_Long2 TRI SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
* 替代气候风险词典
reghdfe Fin_Total TRI_v2 SSI_strict CCI_strict $controls, ///
    absorb(stkcd year) vce(cluster stkcd)
reghdfe Fin_Total TRI_v3 SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
reghdfe Fin_Total TRI_98 SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)
reghdfe Fin_Total CRI_98 $controls, absorb(stkcd year) vce(cluster stkcd)

**纳入货币资金后的稳健性检验
reghdfe Fin_Total_cash TRI SSI CCI $controls, absorb(stkcd year) vce(cluster stkcd)

