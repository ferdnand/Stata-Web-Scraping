clear all 
pause on 

tempfile cats
set obs 1
gen k = 1 
save `cats', replace


local url "https://www.scimagojr.com/journalrank.php?category=1101&area=1100&type=j"
local area "1100 1200 1300 1400 1500 1600 1700 1800 3500 1900 2000 2100 2200 2300 3600 2400 2500 2600 2700 1000 2800 2900 3000 3100 3200 3300 3400"

local category "1402 3102 2902 2202 1302 1101 1102 2602 2603 1602 2702 2703 1103 3314 2604 2402 3202 1104 3302 1204 2216 1702 1201 2903 3103 1902 3107 2203 2802 1303 1301 2704 1502 2803 2502 2204 1304 1305 2215 1403 1401 1306 2705 2904 1503 1307 2804 2503 1501 1504 1601 3602 2205 1205 1308 3203 2805 1505 3315 2905 2707 3603 2605 2206 1703 1704 1705 1706 1701 1707 1903 3104 1206 2606 2207 2706 2906 3316 1801 3317 3502 3503 3501 2708 3303 3204 1309 2806 2607 3002 2709 1901 1904 2302 2303 1105 1905 2002 2001 3304 3399 2208 1603 2504 2710 3604 2711 2907 2807 1310 2712 2102 2101 2201 2304 2305 2301 2713 3402 3205 2714 1506 2003 1507 3403 1106 1107 2103 2908 2715 3318 1311 2716 1906 3305 1907 2608 1908 1909 2717 2909 2306 1708 2718 3605 2719 3601 3306 2307 2720 2721 2722 1202 1207 1108 3307 1709 2403 2723 2401 2209 1410 2725 1710 1802 1604 1109 3105 2724 2910 3308 2911 3309 3319 3310 1208 2609 2912 1404 2308 1405 1803 1406 2505 2501 2913 2610 2601 2210 2211 2214 2914 3606 3607 3608 2701 2506 2404 2726 2611 1312 1313 1000 1209 1210 2509 2309 2727 2808 2728 3206 2801 3106 2104 2612 2915 2901 2916 2729 3609 2212 1910 2730 2917 2731 3610 3504 1605 1407 3505 2732 2733 1911 2405 2734 2918 2919 2735 3506 3003 3004 2736 2920 3001 3611 1211 1606 3612 3101 1314 2737 1110 3613 3320 2310 2507 1508 2738 3201 3321 2739 2740 3108 3614 2741 2742 1212 2105 2743 2922 3615 2923 2744 2745 3311 2213 2809 1711 3404 3207 3301 3323 3312 1712 1111 1912 1607 3616 3699 3109 2613 1804 1408 1913 1315 3110 2508 2746 2614 1409 3005 2747 3313 3322 2748 3401 2406 1213 2311 2312"

foreach i of local area {
	di "area `i'"
	local apref = substr("`i'", 1,2)
	di "`apref'"
	
	foreach j of local category {
		local cpref = substr("`j'", 1, 2)
		local csuff = substr("`j'", -2, .)
		di "`cpref'"
		
		if "`cpref'" == "`apref'" {
			readhtmltable "https://www.scimagojr.com/journalrank.php?category=`j'&area=`i'&type=j"

			foreach var of varlist * {
				replace `var' = subinstr(`var' , ".", "", .) in 1
				replace `var' = subinstr(`var' , " ", "", .) in 1
				replace `var' = subinstr(`var' , "(", "_", .) in 1
				replace `var' = subinstr(`var' , ")", "", .) in 1
				replace `var' = subinstr(`var' , "/", "", .) in 1
				
				local vname = `var'[1]
				di "`vname'"
				cap ren `var' `vname'
			}
			
			gen sourcefile = "`j'"
			append using `cats'
			save `cats', replace
		}   // end of each category within each area
	} // end of each category
} end of each area



drop k
drop if Type == "type"
drop if mi(Type)

compress
aligncase lower
destring *, replace

rename *, lower
ren t1c13 percFemale_2023

lab var hindex "Journal's number of articles (h) that have received at least h citations over the whole period"
lab var totaldocs_2023 "Journal's published articles in 2023 All type of documents are considered"
lab var totaldocs_3years "Journal's published articles in 2022, 2021 and 2020. All type of documents are considered"
lab var totalrefs_2023 "Number of references included in the journal's published articles in 2023"
lab var totalcites_3years "Citations in 2023 received by journal's documents published in 2022, 2021 and 2020"
lab var citabledocs_3years "Journal's citable documents in 2022, 2021 and 2020. Citable documents include: articles, reviews and conference papers"
lab var citesdoc_2years "Average citation per document in a 2 year period. This metric is widely used as impact index"
lab var refdoc_2023 "Average amount of references per document in 2023"
lab var percFemale_2023 "Percentage of female authors in 2023"





