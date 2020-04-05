clear all
set more off
pause on
set varabbrev on, perm

// net install readhtml, from(https://ssc.wisc.edu/sscc/stata/)
** set globals 
	global url "https://www.kenyaprimaryschools.com/"

	cd "C:\Users\EA User\Documents\GitHub\Stata Web Scraping\Kenya Primary Schools\Raw Data"

** Set-up programs necessary for cleaning
	cap program drop clean_stacks
	program define clean_stacks
		args vname
		drop if inlist(`vname',"disclaimer","privacy policy")
		drop if mi(`vname')

		replace `vname' = subinstr(`vname',".","",.)
		replace `vname' = regexr(`vname', "\&\#[0-9]+;","")
		replace `vname' = trim(itrim(`vname'))
		replace `vname' = subinstr(`vname'," ","-",.)
		replace `vname' = subinstr(`vname',"/","",.)
	end 

	program define getSchls
		args weblink 

		drop _all
		set obs 1

		gen page = fileread("`weblink'")
		quietly {
			egen alist = noccur(page), s("</article>")

			if `=alist[1]' > 0 {
				forval z=1/`=alist[1]' {
			        gen start`z'=strpos(page,"<article ")
			        gen end`z'=strpos(page,"</article")
			        gen list`z'=substr(page,start`z',end`z'-start`z'+9)

			        replace page=subinstr(page,"<article ","",1)
			        replace page=subinstr(page,"</article","",1)
				}
		 		
		 		keep page list*
				gen source = "`weblink'"

				xtractSchName
			}
			else {
				replace page = "`weblink'"
			}
		}
	end 

	program define xtractSchName 
		foreach var of varlist list* {
		    replace `var' = substr(`var', strpos(`var', "title=")+7, strpos(`var',"<img ")-strpos(`var', "title=")-9)
		    replace `var' = regexr(`var', "\&\#[0-9]+;","")
		}
		compress
	end
** read home page into stata
/* 	readhtmllist ${url} 
	aligncase lower


	matrix full = (0)
	foreach var of varlist * {
		encode `var', gen(enc_`var') label(subcounties)
		qui tab enc_`var' , matrow(subNums)

		mat full = full\subNums
	}

	svmat full
	label value full subcounties 
	decode full, gen(subcounties)
	keep subcounties

	clean_stacks subcounties

	tempfile subc_data
	save `subc_data'


	levelsof subcounties, local(subcs)

	drop _all
	set obs 1
	gen subcounties = ""
	tempfile locn_data
	save `locn_data'

	foreach subc of local subcs {
		local subc_url  ${url}`subc'`c(dirsep)'
		readhtmllist `subc_url'
		aligncase lower

		stack  list* , into(locn) clear
		keep locn
		clean_stacks locn

		gen subcounties = "`subc'"
		// merge m:1 subcounties using `subc_data' , nogen assert(match using) 
		append using `locn_data'
		save `locn_data', replace

	}
	merge m:1 subcounties using `subc_data' , nogen // assert(match using) 
	drop if mi(locn
	save location_data, replace
 
	use location_data, clear
	gen sublocn_url = "${url}" + subcounties + "/" + locn +"/"
	drop if mi(sublocn_url)

	local nlocns `=_N'
	di `nlocns'
	compress
	tempfile subc_locn_data
	save `subc_locn_data'

	drop _all
	set obs 1
	
	tempfile schls_url
	save `schls_url', emptyok

** Go through every sublocation within a location
	forvalues i = 1/`nlocns' {
		use `subc_locn_data', clear
		local sublocn_url = sublocn_url[`i']
		drop _all
		set obs 1

		gen page = fileread("`sublocn_url'")
		egen nlist = noccur(page), s("</li>")
		egen nlists = noccur(page), s("<li ")
		if `=nlist[1]' > 0 {
			forval t=1/`=nlist[1]' {
		        gen start`t'=strpos(page,"<li ")
		        gen end`t'=strpos(page,"</li")
		        gen list`t'=substr(page,start`t',end`t'-start`t'+5)

		        replace page=subinstr(page,"<li ","",1)
		        replace page=subinstr(page,"</li","",1)
			}

			stack list* , into(sublocn) clear
			aligncase lower
			drop if regexm(sublocn,"privacy policy|disclaimer")

			gen url_s = strpos(sublocn,"href="+char(34))
			gen url_e = strpos(sublocn,"/"+char(34)+">")

			gen schls_url = substr(sublocn,url_s+6,url_e-url_s-5)

			append using `schls_url'
			save `schls_url', replace
		}

		if mod(`i',100) ==0 {
			save sublocn_url_data_`i' , replace
		}
	}
*/

	use schls_url using sublocn_url_data, clear
	drop if mi(schls_url)

	local alocns `=_N'
	di `alocns'

	compress
	tempfile subc_locn_data
	save `subc_locn_data'

	drop _all
	set obs 1
	
	tempfile schls_list
	save `schls_list', emptyok

** Go through every sublocation within a location
	forvalues j = 1/`alocns' {
		use in `j' using `subc_locn_data', clear
		local sch_url = schls_url[1]
		di "`j'   --   `sch_url'"
		drop _all
		set obs 1 
	
		getSchls `sch_url'
		append using `schls_list'
		save `schls_list', replace


		if regexm(page, "(Page [0-9] of [0-9]+)") > 0 {
			gen npages = regexs(1) if regexm(page, "(Page [0-9] of [0-9]+)")
			replace npages = regexr(npages, "Page [0-9] of ", "")
			local npages = npages[1]

			if `npages' > 0 {
				forvalues np = 2/`npages' {
					local sch_url`np' "`sch_url'page/`np'/"
					di "`np'   --   `sch_url`np''"
					drop _all
					set obs 1

					getSchls `sch_url`np''

					append using `schls_list'
					save `schls_list', replace
				}
			}
		}
		
		if mod(`j',100) ==0 {
			save schools_interim_data_`j' , replace
			drop in 1/`=_N'
			
			save `schls_list', replace
		}
	}


