/// ==================================================================================== //
//   Gmacs: A generalized size-structured stock assessment modeling framework.
//
//   Authors: gmacs development team at the
//            Alaska Fisheries Science Centre, Seattle
//            and the University of Washington
//
//   Info: https://github.com/seacode/gmacs Copyright (C) 2014. All rights reserved.
//   
//  ACKNOWLEDGEMENTS
// 		- finacial support provided by NOAA and Bering Sea Fisheries Research Foundation.
//
//  INDEXES:
//    g = group
//    h = sex
//    i = year
//    j = time step (years)
//    k = gear or fleet
//    l = index for length class
//    m = index for maturity state
//    o = index for shell condition.
// 
//  OUTPUT FILES:
//    gmacs.rep  Main result file for reading into R etc
//    gmacs.std  Result file for reading into R etc
//
//   FOR DEBUGGING INPUT FILES: (for accessing easily with read_admb() function)
//    gmacs_files_in.dat  Which control and data files were specified for the current run
//    gmacs_in.ctl        Code-generated copy of control file content (useful for checking read)
//    gmacs_in.dat        Code-generated copy of data file content (useful for checking read)
//
//   TO ECHO INPUT 
//    checkfile.rep      All of data read in 
//
//
// ==================================================================================== //







DATA_SECTION
	
	friend_class gmacs_comm;
	// |---------------------|
	// | SIMULATION CONTROLS |
	// |---------------------|
	
	int simflag; 
	!! ///> flag for simulating data 
	int rseed
	LOC_CALCS
		simflag = 0;
		rseed   = 0;
		int opt,on;

		/**
		 * @brief command line option for simulating data.
		 */
		if((on=option_match(ad_comm::argc,ad_comm::argv,"-sim",opt))>-1)
		{
			simflag = 1;
			rseed   = atoi(ad_comm::argv[on+1]);
		}

		if((on=option_match(ad_comm::argc,ad_comm::argv,"-i",opt))>-1)
		{
			cout<<"\n";
			cout<<"  |----------------------------------------------------------|\n";
			cout<<"  | CONTRIBUTIONS (code and intellectual)                    |\n";
			cout<<"  |----------------------------------------------------------|\n";
			cout<<"  | Name:                        Organization:               |\n";
			cout<<"  | James Ianelli                NOAA-NMFS                   |\n";
			cout<<"  | Darcy Webber                 NOAA-NMFS Contractor        |\n";
			cout<<"  | Steven Martell               IPHC                        |\n";
			cout<<"  | Jack Turnock                 NOAA-NMFS                   |\n";
			cout<<"  | Jie Zheng 	                  ADF&G                       |\n";
			cout<<"  | Hamachan Hamazaki 	          ADF&G                       |\n";
			cout<<"  | Athol Whitten                University of Washington    |\n";
			cout<<"  | Andre Punt                   University of Washington    |\n";
			cout<<"  | Dave Fournier                Otter Research              |\n";
			cout<<"  | John Levitt                  Mathemetician               |\n";
			cout<<"  |----------------------------------------------------------|\n";
			cout<<"\n";
			cout<<"  |----------------------------------------------------------|\n";
			cout<<"  | FINANCIAL SUPPORT                                        |\n";
			cout<<"  |----------------------------------------------------------|\n";
			cout<<"  | Financial support for this project was provided by the   |\n";
			cout<<"  | National Marine Fisheries Service, the Bering Sea        |\n";
			cout<<"  | Fisheries Research Foundation,....                       |\n";
			cout<<"  |----------------------------------------------------------|\n";
			cout<<"\n";
			cout<<"  |----------------------------------------------------------|\n";
			cout<<"  | DOCUMENTATION                                            |\n";
			cout<<"  |----------------------------------------------------------|\n";
			cout<<"  | online api: http://seacode.github.io/gmacs/index.html    |\n";
			cout<<"  |----------------------------------------------------------|\n";
			cout<<"\n";
			exit(1);
		}

		// Command line option here to do retrospective analysis
		if((on=option_match(ad_comm::argc,ad_comm::argv,"-retro",opt))>-1)
		{
			cout<<"\n";
			cout<<"  |----------------------------------------------------------|\n";
			cout<<"  | Running retrospective model with "<< ad_comm::argv[on+1]<<" recent yrs removed |\n";
			cout<<"  |----------------------------------------------------------|\n";
			cout<<"  |  YET TO BE IMPLEMENTED                                   |\n";
			cout<<"  |----------------------------------------------------------|\n";
			exit(1);
		}
	END_CALCS

	// |------------------------|
	// | DATA AND CONTROL FILES |
	// |------------------------|
	init_adstring datafile;
	init_adstring controlfile;

	
	!! ad_comm::change_datafile_name(datafile); WriteFileName(datafile);WriteFileName(controlfile);

	// |------------------|
	// | MODEL DIMENSIONS |
	// |------------------|
	init_int syr;           ///> initial year
	init_int nyr;         	///> terminal year
	init_number jstep;      ///> time step (years)
	init_int nfleet;        ///> number of gears
	init_int nsex;          ///> number of sexes
	init_int nshell;        ///> number of shell conditions
	init_int nmature;       ///> number of maturity types
	init_int nclass;        ///> number of size-classes
	LOC_CALCS
		WRITEDAT(syr); 
		WRITEDAT(nyr); 
		WRITEDAT(jstep); 
		WRITEDAT(nfleet); 
		WRITEDAT(nsex); 
		WRITEDAT(nshell);
		WRITEDAT(nmature);
		WRITEDAT(nclass);
	END_CALCS
	int n_grp;              ///> number of sex/newshell/oldshell groups
	!! n_grp = nsex * nshell * nmature;
	int nlikes
                       //   1      2       3         4          5             
	!! nlikes = 5; // (catch, cpue, sizecomps, recruits, molt_increment data)

	// Set up index pointers
	ivector isex(1,n_grp);
	ivector ishell(1,n_grp);
	ivector imature(1,n_grp);
	3darray pntr_hmo(1,nsex,1,nmature,1,nshell);
	LOC_CALCS
		int h,m,o;
		int hmo=1;
		for( h = 1; h <= nsex; h++ )
		{
			for( m = 1; m <= nmature; m++ )
			{
				for( o = 1; o <= nshell; o++ )
				{
					isex(hmo) = h;
					ishell(hmo) = o;
					imature(hmo) = m;
					pntr_hmo(h,m,o) = hmo++;
				}
			}
		}
	END_CALCS



	init_vector size_breaks(1,nclass+1);
	vector      mid_points(1,nclass);
	!! mid_points = size_breaks(1,nclass) + 0.5 * first_difference(size_breaks);
	!!  WRITEDAT(size_breaks);

	// |-----------|
	// | ALLOMETRY |
	// |-----------|
	init_vector lw_alfa(1,nsex);
	init_vector lw_beta(1,nsex);
	matrix mean_wt(1,nsex,1,nclass);
	LOC_CALCS
		for(int h = 1; h <= nsex; h++ )
		{
			mean_wt(h) = lw_alfa(h) * pow(mid_points,lw_beta(h));
		}
	END_CALCS
	!! WRITEDAT(lw_alfa); WRITEDAT(lw_beta); ECHO(mean_wt);

	// |-------------------------------|
	// | FECUNDITY FOR SSB CALCULATION |
	// |-------------------------------|
	init_vector fecundity(1,nclass);
	init_matrix maturity(1,nsex,1,nclass);
	!! WRITEDAT(fecundity); WRITEDAT(maturity); 

	// |-------------|
	// | FLEET NAMES |
	// |-------------|
	init_adstring name_read_flt;        
	init_adstring name_read_srv;
	!! WRITEDAT(name_read_srv); WRITEDAT(name_read_flt);

	// |--------------|
	// | CATCH SERIES |
	// |--------------|
	//init_int nCatchRows;                      // number of rows in dCatchData
	init_int nCatchDF;
	init_ivector nCatchRows(1,nCatchDF);
	init_3darray dCatchData(1,nCatchDF,1,nCatchRows,1,11);  // array of catch data
	matrix obs_catch(1,nCatchDF,1,nCatchRows);
	matrix  catch_cv(1,nCatchDF,1,nCatchRows);
	matrix  catch_dm(1,nCatchDF,1,nCatchRows);
	matrix  catch_mult(1,nCatchDF,1,nCatchRows);
	LOC_CALCS
		for(int k = 1; k <= nCatchDF; k++ )
		{
			catch_mult(k) = column(dCatchData(k),9);
			obs_catch(k)  = column(dCatchData(k),5);
			catch_cv(k)   = column(dCatchData(k),6);
			catch_dm(k)   = column(dCatchData(k),11);

			// rescale catch by multiplier.
			obs_catch(k) = elem_prod(obs_catch(k),catch_mult(k));
		}
		WRITEDAT(nCatchDF); WRITEDAT(nCatchRows); WRITEDAT(dCatchData);
	END_CALCS
	//!! ECHO(obs_catch); ECHO(catch_cv);

	// From the catch series determine the number of fishing mortality
	// rate parameters that need to be estimated.  Note that  there is
	// a number of combinations which require a F to be estimated. The
	// ivector nFparams is the number of deviations required for each 
	// fleet, and nYparams is the number of deviations for female Fs.
	ivector nFparams(1,nfleet);
	ivector nYparams(1,nfleet);
	ivector foff_phz(1,nfleet);
	imatrix fhit(syr,nyr,1,nfleet);
	imatrix yhit(syr,nyr,1,nfleet);
	matrix  dmr(syr,nyr,1,nfleet);

	LOC_CALCS
		nFparams.initialize();
		nYparams.initialize();
		fhit.initialize();
		yhit.initialize();
		dmr.initialize();
		foff_phz = -1;
		for(int k = 1; k <= nCatchDF; k++ )
		{
			for(int i = 1; i <= nCatchRows(k); i++ )
			{
				int g = dCatchData(k)(i,3);
				int y = dCatchData(k)(i,1);
				int h = dCatchData(k)(i,4);
				if(!fhit(y,g))
				{
					fhit(y,g)   ++;
					nFparams(g) ++;
					dmr(y,g) = catch_dm(k)(i);
				}
				if(!yhit(y,g) && h == 2)
				{
					yhit(y,g)   ++;
					nYparams(g) ++;
					foff_phz(g) = 1;
					dmr(y,g) = catch_dm(k)(i);
				}
			}
		}
	END_CALCS


	// |----------------------------|
	// | RELATIVE ABUNDANCE INDICES |
	// |----------------------------|
	init_int nSurveys;
	init_ivector nSurveyRows(1,nSurveys);
	init_3darray dSurveyData(1,nSurveys,1,nSurveyRows,1,7);
	matrix obs_cpue(1,nSurveys,1,nSurveyRows);
	matrix  cpue_cv(1,nSurveys,1,nSurveyRows);
	LOC_CALCS
		for(int k = 1; k <= nSurveys; k++ )
		{
			obs_cpue(k) = column(dSurveyData(k),5);
			cpue_cv(k)  = column(dSurveyData(k),6);
		}
		WRITEDAT(nSurveys);WRITEDAT(nSurveyRows);WRITEDAT(dSurveyData); 
		ECHO(obs_cpue); ECHO(cpue_cv); 
	END_CALCS


	// |-----------------------|
	// | SIZE COMPOSITION DATA |
	// |-----------------------|
	init_int nSizeComps;
	init_ivector nSizeCompRows(1,nSizeComps);
	init_ivector nSizeCompCols(1,nSizeComps);
	init_3darray d3_SizeComps(1,nSizeComps,1,nSizeCompRows,-7,nSizeCompCols);
	3darray d3_obs_size_comps(1,nSizeComps,1,nSizeCompRows,1,nSizeCompCols);
	3darray d3_res_size_comps(1,nSizeComps,1,nSizeCompRows,1,nSizeCompCols);
	matrix size_comp_sample_size(1,nSizeComps,1,nSizeCompRows);
	LOC_CALCS
		for(int k = 1; k <= nSizeComps; k++)
		{
			dmatrix tmp = trans(d3_SizeComps(k)).sub(1,nSizeCompCols(k));
			d3_obs_size_comps(k) = trans(tmp);
			// NOTE This normalizes all observations by row--may be incorrect if shell condition
			for (int i=1;i<=nSizeCompRows(k);i++)
			{
			   d3_obs_size_comps(k,i) /= sum(d3_obs_size_comps(k,i));
			}
			size_comp_sample_size(k) = column(d3_SizeComps(k),0);
		}
		WRITEDAT(nSizeComps);WRITEDAT(nSizeCompRows);  WRITEDAT(nSizeCompCols); WRITEDAT(d3_SizeComps); ECHO(d3_obs_size_comps); 
	END_CALCS
	ivector ilike_vector(1,nlikes)
	LOC_CALCS
	  ilike_vector(1) = nCatchDF;
	  ilike_vector(2) = nSurveys;
	  ilike_vector(3) = nSizeComps;
	  ilike_vector(4) = 1;
	  ilike_vector(5) = 1;
	END_CALCS


	// |-----------------------|
	// | Growth increment data |
	// |-----------------------|
	init_int nGrowthObs;
	init_matrix dGrowthData(1,nGrowthObs,1,4);
	vector     dPreMoltSize(1,nGrowthObs);
	ivector     iMoltIncSex(1,nGrowthObs);
	vector         dMoltInc(1,nGrowthObs);
	vector       dMoltIncCV(1,nGrowthObs);
	vector mle_alpha(1,nsex);
	vector mle_beta(1,nsex);
	LOC_CALCS
		dPreMoltSize = column(dGrowthData,1);
		iMoltIncSex  = ivector(column(dGrowthData,2));
		dMoltInc     = column(dGrowthData,3);
		dMoltIncCV   = column(dGrowthData,4);

		dvector xybar(1,nsex);
		dvector xx(1,nsex);
		dvector xbar(1,nsex);
		dvector ybar(1,nsex);
		ivector nh(1,nsex);

		nh.initialize();
		xybar.initialize();
		xbar.initialize();
		ybar.initialize();
		xx.initialize();

		// come up with mle estimates for alpha and beta
		// for the linear growth increment model.
		if(nGrowthObs)
		{
			for(int i = 1; i <= nGrowthObs; i++ )
			{
				int h = iMoltIncSex(i);
				
				nh(h)++;
				xybar(h) += dPreMoltSize(i) * dMoltInc(i);
				xbar(h)  += dPreMoltSize(i); 
				ybar(h)  += dMoltInc(i);
				xx(h)    += square(dPreMoltSize(i));
			}
			for( h = 1; h <= nsex; h++ )
			{
				xybar(h) /= nh(h);
				xbar(h)  /= nh(h);
				ybar(h)  /= nh(h);
				xx(h)    /= nh(h);

				double slp = (xybar(h) - xbar(h)*ybar(h)) / (xx(h) - square(xbar(h)));
				double alp = ybar(h) - slp*xbar(h);
				mle_alpha(h) = alp;
				mle_beta(h)  = -slp;
			}
						
		}
	  WRITEDAT(nGrowthObs); 
	  WRITEDAT(dGrowthData); 
	  ECHO(dPreMoltSize); 
	  ECHO(iMoltIncSex); 
	  ECHO(dMoltInc); 
	  ECHO(dMoltIncCV); 
	END_CALCS

	// |------------------|
	// | END OF DATA FILE |
	// |------------------|
	init_int eof;
	!! WRITEDAT(eof);
	!! if (eof != 9999) {cout<<"Error reading data"<<endl; exit(1);}










	!! ad_comm::change_datafile_name(controlfile);
	// |----------------------------|
	// | LEADING PARAMETER CONTROLS |
	// |----------------------------|
	!! cout<<"*** Reading control file ***"<<endl;
	init_int ntheta;
	init_matrix theta_control(1,ntheta,1,7);
	
	vector theta_ival(1,ntheta);
	vector theta_lb(1,ntheta);
	vector theta_ub(1,ntheta);
	ivector theta_phz(1,ntheta);
	LOC_CALCS
		theta_ival = column(theta_control,1);
		theta_lb   = column(theta_control,2);
		theta_ub   = column(theta_control,3);
		theta_phz  = ivector(column(theta_control,4));
	END_CALCS

	// |----------------------------|
	// | GROWTH PARAMETER CONTROLS  |
	// |----------------------------|
	// | Note that if bUseEmpiricalGrowth data is TRUE, then cannot estimate alpa & beta.
	int nGrwth;
	!! nGrwth = nsex*5;
	init_matrix Grwth_control(1,nGrwth,1,7);

	vector  Grwth_ival(1,nGrwth);
	vector  Grwth_lb(1,nGrwth);
	vector  Grwth_ub(1,nGrwth);
	ivector Grwth_phz(1,nGrwth);
	// ivector ipar_vector(1,nGrwth);
	LOC_CALCS
		// ipar_vector = nsex;
		Grwth_ival  = column(Grwth_control,1);
		Grwth_lb    = column(Grwth_control,2);
		Grwth_ub    = column(Grwth_control,3);
		Grwth_phz   = ivector(column(Grwth_control,4));
		WriteCtl(ntheta); 
		WriteCtl(theta_control); 
		WriteCtl(Grwth_control);
	END_CALCS

	// |--------------------------------|
	// | SELECTIVITY PARAMETER CONTROLS |
	// |--------------------------------|
	int nr;
	int nc;
	int nslx;
	// This seems off by a factor of 2...for single sex models...???but maybe not...
	!! nr = 2 * nfleet;
	// !! nr = nsex * nfleet;
	!! nc = 13;
	init_ivector slx_nsel_blocks(1,nr);
	!! nslx = sum(slx_nsel_blocks);
	init_imatrix slx_nret(1,nsex,1,nfleet);

	init_matrix slx_control(1,nslx,1,nc);
	!! 	WriteCtl(slx_nsel_blocks); WriteCtl(slx_nret); WriteCtl(slx_control);

	ivector slx_indx(1,nslx);
	ivector slx_type(1,nslx);
	ivector slx_phzm(1,nslx);
	ivector slx_bsex(1,nslx);           // boolean 0 sex-independent, 1 sex-dependent
	ivector slx_xnod(1,nslx);
	ivector slx_inod(1,nslx);
	ivector slx_rows(1,nslx);
	ivector slx_cols(1,nslx);
	 vector slx_mean(1,nslx);
	 vector slx_stdv(1,nslx);
	 vector slx_lam1(1,nslx);
	 vector slx_lam2(1,nslx);
	 vector slx_lam3(1,nslx);
	ivector slx_styr(1,nslx);
	ivector slx_edyr(1,nslx);

	LOC_CALCS
		slx_indx = ivector(column(slx_control,1));
		slx_type = ivector(column(slx_control,2));
		slx_mean = column(slx_control,3);
		slx_stdv = column(slx_control,4);
		slx_bsex = ivector(column(slx_control,5));
		slx_xnod = ivector(column(slx_control,6));
		slx_inod = ivector(column(slx_control,7));
		slx_phzm = ivector(column(slx_control,8));
		slx_lam1 = column(slx_control,9);
		slx_lam2 = column(slx_control,10);
		slx_lam3 = column(slx_control,11);
		slx_styr = ivector(column(slx_control,12));
		slx_edyr = ivector(column(slx_control,13));

		// count up number of parameters required
		slx_rows.initialize();
		slx_cols.initialize();
		for(int k = 1; k <= nslx; k++ )
		{
			/* multiplier for sex dependent selex */
			int bsex = 1;
			if(slx_bsex(k)) bsex = 2;   
			
			switch (slx_type(k))
			{
				case 1: // coefficients
					slx_cols(k) = nclass - 1;
					slx_rows(k) = bsex;
				break;

				case 2: // logistic
					slx_cols(k) = 2;
					slx_rows(k) = bsex;
				break;

				case 3: // logistic95
					slx_cols(k) = 2;
					slx_rows(k) = bsex;
				break;
			}
			// ivector tmp = ivector(slx_control(k).sub(12,11+slx_nsel_blocks(k)));
			// slx_blks(k) = tmp.shift(1);
		}
	END_CALCS

	// |---------------------------------------------------------|
	// | PRIORS FOR CATCHABILITIES FOR INDICES                   |
	// |---------------------------------------------------------|
	init_matrix q_controls(1,nSurveys,1,4);
	vector prior_qbar(1,nSurveys);
	vector prior_qsd(1,nSurveys);
	vector prior_qtype(1,nSurveys);
	vector cpue_lambda(1,nSurveys);
	LOC_CALCS
		prior_qtype = column(q_controls,1);
		prior_qbar  = column(q_controls,2);
		prior_qsd   = column(q_controls,3);
		cpue_lambda = column(q_controls,4);
		WriteCtl(q_controls); 
		ECHO(prior_qtype); 
		ECHO(prior_qbar); 
		ECHO(prior_qsd); 
		ECHO(cpue_lambda);
	END_CALCS

	// |---------------------------------------------------------|
	// | PENALTIES FOR MEAN FISHING MORTALITY RATE FOR EACH GEAR |
	// |---------------------------------------------------------|
	init_matrix f_controls(1,nfleet,1,4);
	ivector f_phz(1,nfleet);
	vector pen_fbar(1,nfleet);
	vector log_pen_fbar(1,nfleet);
	matrix pen_fstd(1,2,1,nfleet);
	LOC_CALCS
		pen_fbar = column(f_controls,1);
		log_pen_fbar = log(pen_fbar+1.0e-14);
		for(int i=1; i<=2; i++)
			pen_fstd(i) = trans(f_controls)(i+1);
		f_phz    = ivector(column(f_controls,4));
		// Set foff_phz to f_phz
		for(int k = 1; k <= nfleet; k++ )
		{
			for(int i = syr; i <= nyr; i++ )
			{
				if( yhit(i,k) ) 
				{
					foff_phz(k) = f_phz(k);
					break;
				}
			}           
		}
		WriteCtl(f_controls); ECHO(f_phz); 
	END_CALCS

	// |-----------------------------------|
	// | OPTIONS FOR SIZE COMPOSITION DATA |
	// |-----------------------------------|
	init_ivector nAgeCompType(1,nSizeComps);
	init_ivector bTailCompression(1,nSizeComps);
	init_ivector nvn_phz(1,nSizeComps);
	init_ivector iCompAggregator(1,nSizeComps);
	// LOC_CALCS
		// int iAggComps = max(iCompAggregator);
	// END_CALCS
  // 
	// 3darray d3_obs_agg_comps(1,nAggComps,1,nAggCompRows,1,nAggCompCols);
	// 3darray d3_res_agg_comps(1,nAggComps,1,nAggCompRows,1,nAggCompCols);
	// matrix agg_comp_sample_size(1,nAggComps,1,nAggCompRows);
  // 
	// LOC_CALCS
		// for(int k = 1; k <= nSizeComps; k++)
		// {
		        // iCompAggregator(k)
			// dmatrix tmp = trans(d3_SizeComps(k)).sub(1,nSizeCompCols(k));
			// d3_obs_size_comps(k) = trans(tmp);
			// for (int i=1;i<=nSizeCompRows(k);i++)
			// {
			   // d3_obs_size_comps(k,i) /= sum(d3_obs_size_comps(k,i));
			// }
			// size_comp_sample_size(k) = column(d3_SizeComps(k),0);
		// }
		// ivector nAggCompRows(1,nAggComps);
		// ivector nAggCompCols(1,nAggComps);
		// 3darray d3_AggComps(1,nAggComps,1,nAggCompRows,-7,nAggCompCols);
	// END_CALCS


	LOC_CALCS
		for(int k = 1; k <= nSizeComps; k++ )
		{
			dmatrix tmp = trans(d3_SizeComps(k)).sub(1,nSizeCompCols(k));
			d3_obs_size_comps(k) = trans(tmp);
			// NOTE This normalizes all observations by row--may be incorrect if shell condition
			for (int i=1;i<=nSizeCompRows(k);i++)
			{
			   d3_obs_size_comps(k,i) /= sum(d3_obs_size_comps(k,i));
			}
			size_comp_sample_size(k) = column(d3_SizeComps(k),0);
		}
		//WRITEDAT(nSizeComps); WRITEDAT(nSizeCompRows); WRITEDAT(nSizeCompCols); WRITEDAT(d3_SizeComps); ECHO(d3_obs_size_comps);
	END_CALCS
  !!	WriteCtl(nAgeCompType); WriteCtl(bTailCompression); WriteCtl(nvn_phz); 

	// |--------------------------------------------------|
	// | OPTIONS FOR TIME-VARYING NATURAL MORTALITY RATES |
	// |--------------------------------------------------|
	int nMdev;
	init_int m_type;
	init_int Mdev_phz;
	init_number m_stdev;
	init_int m_nNodes;
	init_ivector m_nodeyear(1,m_nNodes);
	LOC_CALCS
		switch( m_type )
		{
			case 0:
				nMdev = 0; 
				Mdev_phz = -1;
			break;
			case 1: 
				nMdev = nyr-syr; 
			break;
			case 2:
				nMdev = m_nNodes;
			break;
			case 3:
				nMdev = m_nNodes;
			break;
		}
		WriteCtl(m_type); WriteCtl(Mdev_phz); WriteCtl(m_stdev); WriteCtl(m_nNodes); WriteCtl(m_nodeyear); 
	END_CALCS
	// |--------------------------------------------------|
	// | OPTIONS FOR TIME-VARYING CATCHABILITY            |
	// |--------------------------------------------------|
	int nQdev;
	init_int q_type;
	init_int Qdev_phz;
	init_number q_stdev;
	init_int q_nNodes;
	init_ivector q_nodeyear(1,q_nNodes);
	LOC_CALCS
		switch( q_type )
		{
			case 0:
				nQdev = 0; 
				Qdev_phz = -1;
			break;
			case 1: 
				nQdev = nSurveyRows(1)-1;  // OjO need to generalize for arbitrary number of surveys
			break;
			case 2:
				nQdev = q_nNodes;
			break;
			case 3:
				nQdev = q_nNodes;
			break;
		}
		WriteCtl(q_type); WriteCtl(Qdev_phz); WriteCtl(q_stdev); WriteCtl(q_nNodes); WriteCtl(q_nodeyear); 
	END_CALCS


	// |---------------------------------------------------------|
	// | OTHER CONTROLS                                          |
	// |---------------------------------------------------------|
	init_vector model_controls(1,10);
	int rdv_phz;                            ///> Estimated rec_dev phase
	int verbose;                            ///> Flag to print to screen
	int bInitializeUnfished;                ///> Flag to initialize at unfished conditions
	int spr_syr;
	int spr_nyr;
	number spr_target;
	int spr_fleet;
	number spr_lambda;
	int bUseEmpiricalGrowth;
	int nSRR_flag;
	LOC_CALCS
		rdv_phz             = int(model_controls(1));
		verbose             = int(model_controls(2));
		bInitializeUnfished = int(model_controls(3));
		spr_syr             = int(model_controls(4));
		spr_nyr             = int(model_controls(5));
		spr_target          =     model_controls(6);
		spr_fleet           = int(model_controls(7));
		spr_lambda          =     model_controls(8);
		bUseEmpiricalGrowth = int(model_controls(9));
		nSRR_flag           = int(model_controls(10));
		WriteCtl(model_controls); 
	END_CALCS

	init_int eof_ctl;
	!! WriteCtl(eof_ctl); 
	!!	if(eof_ctl!=9999){cout<<"Error reading control file"<<endl; exit(1);}
	!! cout<<"end of control section"<<endl;


	LOC_CALCS
		// ensure the phase for alpha & beta is -ve for GrowhtPars if bUseEmpiricalGrowth
		COUT(Grwth_phz);
		if(bUseEmpiricalGrowth)
		{
			cerr << "WARNING:\n \tUsing empirical growth increment data,\n";
			cerr << "\talpha & beta parameters will not be estimated."<<endl;
			for (int h=1;h<=nsex;h++)
			{
				int icnt=h;
				Grwth_phz(icnt) = -1;
				icnt += nsex;
				Grwth_phz(icnt) = -1;
			}
		}
	END_CALCS

	int nf;
	!! nf = 0;

	// |----------------------|
	// | SPR Reference points |
	// |----------------------|
	number spr_fspr;
	number spr_bspr;
	number spr_rbar;
	number spr_cofl;
	number spr_fofl;
	number spr_ssbo;

INITIALIZATION_SECTION
	theta     theta_ival;
	Grwth     Grwth_ival;
	log_fbar  log_pen_fbar;
	

PARAMETER_SECTION
	
	// Leading parameters
	// M         = theta(1)
	// ln(Ro)    = theta(2)
	// ln(R1)    = theta(3)
	// ln(Rbar)  = theta(4)
	// ra        = theta(5)
	// rbeta     = theta(6)
	// logSigmaR = theta(7)
	// steepness = theta(8)
	// rho       = theta(9)
	
	init_bounded_number_vector theta(1,ntheta,theta_lb,theta_ub,theta_phz);
	


	// Growth and molting probability parameters Sex-specific
	// alpha    = Grwth(1);
	// beta     = Grwth(2);
	// gscale   = Grwth(3);
	// molt_mu  = Grwth(4);
	// molt_cv  = Grwth(5);

	init_bounded_number_vector Grwth(1,nGrwth,Grwth_lb,Grwth_ub,Grwth_phz);
	

	// Molt increment parameters
	// Need molt increment data to estimate these parameters
	// init_bounded_vector alpha(1,nsex,0,20.,-3);
	// init_bounded_vector beta(1,nsex,0,10,-3);
	// init_bounded_vector scale(1,nsex,1,10.,-4);

	// Molt probability parameters
	// !! double lb = min(size_breaks);
	// !! double ub = max(size_breaks);
	// init_bounded_vector molt_mu(1,nsex,lb,ub,1);
	// init_bounded_vector molt_cv(1,nsex,0,1,1);

	// Selectivity parameters
	// NOTE THIS NEEDS FIXING...cobbled together some bounds to make things work...
	init_bounded_matrix_vector log_slx_pars(1,nslx,1,slx_rows,1,slx_cols,-15,15,slx_phzm);
	LOC_CALCS
		for(int k = 1; k <= nslx; k++ )
		{
			if(slx_type(k) == 2 || slx_type(k) == 3)
			{
				for(int j = 1; j <= slx_rows(k); j++ )
				{
					log_slx_pars(k)(j,1) = log(slx_mean(k));
					log_slx_pars(k)(j,2) = log(slx_stdv(k));
				}
			}
		//COUT(log_slx_pars(k));
		}
	END_CALCS

	// Fishing mortality rate parameters
	init_number_vector log_fbar(1,nfleet,f_phz);                 ///> Male mean fishing mortality
	init_vector_vector log_fdev(1,nfleet,1,nFparams,f_phz);      ///> Male f devs
	init_number_vector log_foff(1,nfleet,foff_phz);              ///> Female F offset to Male F
	init_vector_vector log_fdov(1,nfleet,1,nYparams,foff_phz);   ///> Female F offset to Male F

	// Recruitment deviation parameters
	init_bounded_dev_vector rec_ini(1,nclass,-7.0,7.0,rdv_phz);  ///> initial size devs
	init_bounded_dev_vector rec_dev(syr+1,nyr,-7.0,7.0,rdv_phz); ///> recruitment deviations

	// Time-varying natural mortality rate devs.
	init_bounded_dev_vector m_dev(1,nMdev,-3.0,3.0,Mdev_phz);

	// Time-varying catchability devs.
	init_bounded_dev_vector q_dev(1,nQdev,-3.0,3.0,Qdev_phz);

	// Effective sample size parameter for multinomial
	init_number_vector log_vn(1,nSizeComps,nvn_phz);


	matrix nloglike(1,nlikes,1,ilike_vector);
	vector nlogPenalty(1,7);
	vector priorDensity(1,ntheta+nGrwth+nSurveys);

	objective_function_value objfun;

	number fpen;
	number M0;              ///> natural mortality rate
	number logR0;           ///> logarithm of unfished recruits.
	number logRbar;         ///> logarithm of average recruits(syr+1,nyr)
	number logRini;         ///> logarithm of initial recruitment(syr).
	number ra;              ///> Expected value of recruitment distribution
	number rbeta;           ///> rate parameter for recruitment distribution
	number logSigmaR;       ///> standard deviation of recruitment deviations.
	number steepness;       ///> steepness of the SRR
	number rho;             ///> autocorrelation coefficient in recruitment.

	vector   alpha(1,nsex); ///> intercept for linear growth increment model.
	vector    beta(1,nsex); ///> slope for the linear growth increment model.
	vector  gscale(1,nsex); ///> scale parameter for the gamma distribution.
	vector molt_mu(1,nsex); ///> 50% probability of molting at length each year.
	vector molt_cv(1,nsex); ///> CV in molting probabilility.

	vector rec_sdd(1,nclass); ///> recruitment size_density_distribution

	vector    recruits(syr,nyr); ///> vector of estimated recruits
	vector res_recruit(syr,nyr); ///> vector of estimated recruits
	vector          xi(syr,nyr); ///> vector of residuals for SRR


	vector survey_q(1,nSurveys); ///> scalers for relative abundance indices (q)

	matrix pre_catch(1,nCatchDF,1,nCatchRows);  ///> predicted catch (Baranov eq)
	matrix res_catch(1,nCatchDF,1,nCatchRows);  ///> catch residuals in log-space

	matrix pre_cpue(1,nSurveys,1,nSurveyRows);  ///> predicted relative abundance index
	matrix res_cpue(1,nSurveys,1,nSurveyRows);  ///> relative abundance residuals
	
	matrix molt_increment(1,nsex,1,nclass);     ///> linear molt increment

	///> probability of molting
	matrix molt_probability(1,nsex,1,nclass);   

	3darray growth_transition(1,nsex,1,nclass,1,nclass);
	3darray M(1,nsex,syr,nyr,1,nclass);         ///> Natural mortality
	3darray Z(1,nsex,syr,nyr,1,nclass);         ///> Total mortality
	3darray F(1,nsex,syr,nyr,1,nclass);         ///> Fishing mortality
	3darray P(1,nsex,1,nclass,1,nclass);        ///> Diagonal matrix of molt probabilities

	//3darray N(1,nsex,syr,nyr+1,1,nclass);     ///> Numbers-at-length
	3darray d3_N(1,n_grp,syr,nyr+1,1,nclass);   ///> Numbers-at-sex/mature/shell/length.
	3darray ft(1,nfleet,1,nsex,syr,nyr);        ///> Fishing mortality by gear
	3darray d3_newShell(1,nsex,syr,nyr+1,1,nclass); ///> New shell crabs-at-length.
	3darray d3_oldShell(1,nsex,syr,nyr+1,1,nclass); ///> Old shell crabs-at-length.
	3darray d3_pre_size_comps(1,nSizeComps,1,nSizeCompRows,1,nSizeCompCols);
	3darray d3_res_size_comps(1,nSizeComps,1,nSizeCompRows,1,nSizeCompCols);

	4darray S(1,nsex,syr,nyr,1,nclass,1,nclass);            ///> Surival Rate (S=exp(-Z))
	4darray log_slx_capture(1,nfleet,1,nsex,syr,nyr,1,nclass);
	4darray log_slx_retaind(1,nfleet,1,nsex,syr,nyr,1,nclass);
	4darray log_slx_discard(1,nfleet,1,nsex,syr,nyr,1,nclass);

	//sdreport_vector sd_fbar(1,nfleet);
	sdreport_vector sd_log_recruits(syr,nyr);
	sdreport_vector sd_log_ssb(syr,nyr);
	friend_class population_model;

PRELIMINARY_CALCS_SECTION
	if( simflag )
	{
		if(!global_parfile)
		{
			cerr << "Must have a gmacs.pin file to use the -sim command line option"<<endl;
			ad_exit(1);
		}
		cout<<"|———————————————————————————————————————————|"<<endl;
		cout<<"|*** RUNNING SIMULATION WITH RSEED = "<<rseed<<" ***|"<<endl;
		cout<<"|———————————————————————————————————————————|"<<endl;
		
		simulation_model();
		//exit(1);
	}
	
	if(bUseEmpiricalGrowth)
	{
		int l = 1;
		for(int i = 1; i <= nGrowthObs; i++ )
		{

			int h = dGrowthData(i,2);
			molt_increment(h)(l++) = dGrowthData(i,3);
			if(l > nclass) l=1;
		}
	}

PROCEDURE_SECTION
	// Initialize model parameters
	initialize_model_parameters();
	if( verbose == 1) cout<<"Ok after initializing model parameters ..."<<endl;
	
	// Fishing fleet dynamics ...
	calc_selectivities();
	calc_fishing_mortality();
	if( verbose == 1 ) cout<<"Ok after fleet dynamics ..."<<endl;

	// Population dynamics ...
	if(!bUseEmpiricalGrowth)
	{
		calc_growth_increments();
	}
	calc_molting_probability();
	calc_growth_transition();
	calc_natural_mortality();
	calc_total_mortality();
	calc_recruitment_size_distribution();
	calc_initial_numbers_at_length();
	update_population_numbers_at_length();
	calc_stock_recruitment_relationship();
	if( verbose == 1 ) cout<<"Ok after population dynamcs ..."<<endl;

	// observation models ...
	calc_predicted_catch();
	calc_relative_abundance();
	calc_predicted_composition();
	if( verbose == 1 ) cout<<"Ok after observation models ..."<<endl;

	// objective function ...
	calculate_prior_densities();
	calc_objective_function();
	if( verbose == 1 ) cout<<"Ok after objective function ..."<<endl;

	// sd_report variables
	if( last_phase() ) 
	{
		calc_sdreport();
	}
	nf++;
	

	/**
	 * @brief calculate sdreport variables in final phase
	 */
FUNCTION calc_sdreport
	sd_log_recruits = log(recruits);
	sd_log_ssb = log(calc_ssb());
	
	//for(int k = 1; k <= nfleet; k++ )
	//{
	//	sd_fbar(k) = mean(ft(k));
	//	
	//}
	
	

	/**
	 * @brief Initialize model parameters
	 * @details Set global variable equal to the estimated parameter vectors.
	 * 
	 * SM:  Note if using empirical growth increment data, then alpha and beta
     * Growth parameters should not be estimated.  Need to warn the user
     * if the following condition is true:
     * if( bUseEmpiricalGrowth && ( acitve(alpha) || active(beta) ) )
	 */
FUNCTION initialize_model_parameters
	
	// Get parameters from theta control matrix:
	M0        = theta(1);
	logR0     = theta(2);
	logRini   = theta(3);
	logRbar   = theta(4);
	ra        = theta(5);
	rbeta     = theta(6);
	logSigmaR = theta(7);
	steepness = theta(8);
	rho       = theta(9);

	// init_bounded_number_vector Grwth(1,nGrwth,Grwth_lb,Grwth_ub,Grwth_phz);
	// Get Growth & Molting parameters 
	for (int h=1;h<=nsex;h++)
	{
		int icnt=h;
		alpha(h)     = Grwth(icnt);
		icnt += nsex;
		beta(h)      = Grwth(icnt);
		icnt += nsex;
		gscale(h)    = Grwth(icnt);
		icnt += nsex;
		molt_mu(h)   = Grwth(icnt);
		icnt += nsex;
		molt_cv(h)   = Grwth(icnt);
	}
	

	
	if( ! bUseEmpiricalGrowth )
	{
		alpha     = mle_alpha;
		beta      = mle_beta;
	}
	

	/**
	 * @brief Calculate selectivies for each gear.
	 * @author Steve Martell
	 * @details Three selectivities must be accounted for by each fleet.
	 * 1) capture probability, 2) retention probability, and 3) release probability.
	 * 
	 * Maintain the possibility of estimating selectivity independently for
	 * each sex; assumes there are data to estimate female selex.
	 * 
	 * BUG: There should be no retention of female crabs in the directed fishery.
	 * 
	 * Psuedocode:
	 *  -# Loop over each gear:
	 *  -# Create a pointer array with length = number of blocks
	 *  -# Based on slx_type, fill pointer with parameter estimates.
	 *  -# Loop over years and block-in the log_selectivity at mid points.
	 * 	
	 * 	 Need to deprecate the abstract class for selectivity, 7X slower. 
	 * 	 
	 */
FUNCTION calc_selectivities
	int h,i,j,k;
	int block;
	dvariable p1,p2;
	dvar_vector pv;
	log_slx_capture.initialize();
	log_slx_discard.initialize();
	log_slx_retaind.initialize();

	for( k = 1; k <= nslx; k++ )
	{   
		block = 1;
		gsm::Selex<dvar_vector> * pSLX[slx_rows(k)-1];
		for( j = 0; j < slx_rows(k); j++ )
		{
			switch (slx_type(k))
			{
			case 1:  //coefficients
				pv   = mfexp(log_slx_pars(k)(block));
				pSLX[j] = new gsm::SelectivityCoefficients<dvar_vector>(pv);
			break;

			case 2:  //logistic
				p1 = mfexp(log_slx_pars(k,block,1));
				p2 = mfexp(log_slx_pars(k,block,2));
				pSLX[j] = new gsm::LogisticCurve<dvar_vector,dvariable>(p1,p2);
			break;

			case 3:  // logistic95
				p1 = mfexp(log_slx_pars(k,block,1));
				p2 = mfexp(log_slx_pars(k,block,2));
				pSLX[j] = new gsm::LogisticCurve95<dvar_vector,dvariable>(p1,p2);
			break;
			}
			block ++;
		}
		
		// fill array with selectivity coefficients
		j = 0;
		for( h = 1; h <= nsex; h++ )
		{
			for( i = slx_styr(k); i <= slx_edyr(k); i++ )
			{
				int kk = abs(slx_indx(k));   // gear index
				
				if(slx_indx(k) > 0)
				{
					log_slx_capture(kk)(h)(i) = pSLX[j]->logSelectivity(mid_points);
				}
				else
				{
					log_slx_retaind(kk)(h)(i) = pSLX[j]->logSelectivity(mid_points);
					log_slx_discard(kk)(h)(i) = log(1.0 - exp(log_slx_retaind(kk)(h)(i)) +TINY);
				}
			}
			
			// Increment counter if sex-specific selectivity curves are defined.
			if(slx_bsex(k))  j++;
		}
		
		delete *pSLX;
	}



	/**
	 * @brief Calculate fishing mortality rates for each fleet.
	 * @details For each fleet estimate scaler log_fbar and deviates (f_devs).
	 * 
	 * In the event that there is effort data and catch data, then it's possible
	 * to estimate a catchability coefficient and predict the catch for the
	 * period of missing catch/discard data.  Best option for this would be
	 * to use F = q*E, where q = F/E.  Then in the objective function, minimize
	 * the variance in the estimates of q, and use the mean q to predict catch.
	 * Or minimize the first difference and assume a random walk in q.
	 * 
	 * Note that this function calculates the fishing mortality rate including
	 * deaths due to discards.  Where lambda is the discard mortality rate.
	 * 
	 * Note also that Jie estimates F for retained fishery, f for male discards and
	 * f for female discards.  Not recommended to have separate F' for retained and 
	 * discard fisheries, but might be ok to have sex-specific F's.  
	 * 
	 * TODO 
	 * -[ ] fix discard mortality rate.
	 */
FUNCTION calc_fishing_mortality
	int h,i,k,ik,yk;
	double lambda;      // discard mortality rate
	F.initialize();
	ft.initialize();
	dvariable log_ftmp;
	dvar_vector sel(1,nclass);
	dvar_vector ret(1,nclass);
	dvar_vector tmp(1,nclass);

	for( k = 1; k <= nfleet; k++ )
	{
		for( h = 1; h <= nsex; h++ )
		{
			ik=1; yk=1;
			for( i = syr; i <= nyr; i++ )
			{
				if(fhit(i,k))
				{
					log_ftmp    = log_fbar(k) + log_fdev(k,ik++);
					
					if(yhit(i,k))
					{
						log_ftmp   += (h-1) * (log_foff(k) + log_fdov(k,yk++));
					}
					ft(k)(h)(i) = mfexp(log_ftmp);
					
					lambda = dmr(i,k);
					
					sel = exp(log_slx_capture(k)(h)(i));
					ret = exp(log_slx_retaind(k)(h)(i)) * slx_nret(h,k);
					
					tmp = elem_prod(sel,ret + (1.0 - ret) * lambda);
					
					/*if(sum(tmp)==0 || min(tmp) < 0)
					{
						cerr <<"Selectivity vector for gear "<<k<<" is all 0's ";
						cerr <<"Please fix the selectivity controls."<<endl;
						COUT(tmp);
						exit(1);
					}
					*/
					F(h)(i) += ft(k,h,i) * tmp;
				}
			}
		}
	}


	/**
	 * @brief Compute growth increments 
	 * @details Presently based on liner form
	 * 
	 * @param vSizes is a vector of size data from which to compute predicted values
	 * @param iSex   is an integer vector indexing sex (1 = male, 2 = female )
	 * @return dvar_vector of predicted growth increments
	 */   
FUNCTION dvar_vector calc_growth_increments(const dvector vSizes, const ivector iSex)
	{
	if( vSizes.indexmin() != iSex.indexmin() || vSizes.indexmax() != iSex.indexmax() )
	{
		cerr<<"indices don't match..."<<endl;
		ad_exit(1);
	}
	RETURN_ARRAYS_INCREMENT();
	dvar_vector pMoltInc(1,vSizes.indexmax());
	pMoltInc.initialize();
	int h,i;
	for( i = 1; i <= nGrowthObs; i++ )
	{
		h = iSex(i);
		pMoltInc(i) = alpha(h) - beta(h) * vSizes(i);
	}
	RETURN_ARRAYS_DECREMENT();
	return pMoltInc;
		
	}


	/**
	 * @brief Molt increment as a linear function of pre-molt size.
	 * 
	 * TODO
	 * Option for empirical molt increments.
	 */
FUNCTION calc_growth_increments
	int h,l;
	
	for( h = 1; h <= nsex; h++ )
	{
		for( l = 1; l <= nclass; l++ )
		{
			molt_increment(h)(l) = alpha(h) - beta(h) * mid_points(l);
		}
	}

	/**
	 * \brief Calclate the size transtion matrix.
	 * \Authors Team
	 * \details Calculates the size transition matrix for each sex based on
	 * growth increments, which is a linear function of the size interval, and
	 * the scale parameter for the gamma distribution.  This function does the 
	 * proper integration from the lower to upper size bin, where the mode of 
	 * the growth increment is scaled by the scale parameter.
	 * 
	 * This function loops over sex, then loops over the rows of the size
	 * transition matrix for each sex.  The probability of transitioning from 
	 * size l to size ll is based on the vector molt_increment and the 
	 * scale parameter. In all there are three parameters that define the size
	 * transition matrix (alpha, beta, scale) for each sex.
   	 *
  	 * Issue 112 details some of evolution of code development here
	 */
FUNCTION calc_growth_transition
	//cout<<"Start of calc_growth_transition"<<endl;
	int h,l,ll;
	
	dvariable dMeanSizeAfterMolt;
	dvar_vector psi(1,nclass+1);
	dvar_vector sbi(1,nclass+1);
	dvar_matrix At(1,nclass,1,nclass);
	growth_transition.initialize();


	for( h = 1; h <= nsex; h++ )
	{
		At.initialize();
		sbi = size_breaks / gscale(h);
		
		for( l = 1; l <= nclass; l++ )
		{
			dMeanSizeAfterMolt = (size_breaks(l) + molt_increment(h)(l)) / gscale(h);
			psi.initialize();
			for( ll = l; ll <= nclass+1; ll++ )
			{
				if( ll <= nclass+1 )
				{
					psi(ll) = cumd_gamma(sbi(ll),dMeanSizeAfterMolt);
				}
			}
			At(l)(l,nclass)  = first_difference(psi(l,nclass+1));
			At(l)(l,nclass)  = At(l)(l,nclass) / sum(At(l));
		}
		growth_transition(h) = At;
	}


	/**
	 * @brief Calculate natural mortality array
	 * @details Natural mortality (M) is a 3d array for sex, year and size.
	 * @return NULL
	 * 
	 * todo:  
	 *      - Add time varying components
	 *      - Size-dependent mortality
	 * 
	 */
FUNCTION calc_natural_mortality
	int h;
	M.initialize();
	for( h = 1; h <= nsex; h++ )
	{
		M(h) = M0;
	}
	// Add random walk to natural mortality rate.
	if (active( m_dev ))
	{
		dvar_vector delta(syr+1,nyr);
		delta.initialize();
		delta = get_delta(m_type,syr+1,nyr,m_dev,m_nodeyear,m_nNodes);

		// Update M by year.
		for(int h = 1; h <= nsex; h++ )
		{
			for(int i = syr+1; i <= nyr; i++ )
			{
				M(h)(i)  = M(h)(i-1) * mfexp(delta(i));
			}
		}
	}
	/**
	 * @brief Calculate generic time-varying delta
	 * @details Natural mortality (M) is a 3d array for sex, year and size.
	 * @return dvar_vector of yr-specific changes
	 * @author Jim Ianelli
	 * @issues passes deviation vector as non-constant...ok?
	 * 
	 */
FUNCTION dvar_vector get_delta(const int d_type, const int fy, const int ly,dvar_vector& t_dev,const ivector& _nodeyear,const int nnodes)
		dvar_vector _delta(fy,ly);
		_delta.initialize();
		switch( d_type )
		{
			// would this line ever occur if t_dev active?
			case 0:  // constant natural mortality
				_delta = 0;
			break;

			case 1:  // random walk in natural mortality
				_delta = t_dev.shift(fy);
			break;

			case 2:  // cubic splines
			{
				dvector iyr(1,nnodes);
				iyr = (_nodeyear -syr) / (nyr-syr);
				dvector jyr(syr+1,nyr);
				jyr.fill_seqadd(0,1./(nyr-syr-1));
				vcubic_spline_function csf(iyr,t_dev);
				_delta = csf(jyr);
			}
			break;

			/*
			JIm question about below.  I'm not sure if you were intending to
			have this set up as a random walk, where the shift occurs in a specifc year
			to a new state.  I think what Jie had  was just a block wiht a different
			M and it then returns back to the previous state.
			*/
			case 3:  // Specific break points
			  for (int idev=1;idev<=nnodes;idev++)
			  {
  					_delta(_nodeyear(idev)) = t_dev(idev);
			  }
			break;

		}
		return(_delta);


	/**
	 * @brief Calculate total instantaneous mortality rate and survival rate
	 * @details \f$ S = exp(-Z) \f$
	 * @return NULL
	 * 
	 * ISSUE, for some reason the diagonal of S goes to NAN if linear growth model is used.
	 * Due to F.
	 */
FUNCTION calc_total_mortality
	int h;
	Z.initialize();
	S.initialize();
	for( h = 1; h <= nsex; h++ )
	{
		Z(h) = M(h) + F(h);
	
		for(int i = syr; i <= nyr; i++ )
		{
			for(int l = 1; l <= nclass; l++ )
			{
				S(h)(i)(l,l) = mfexp(-Z(h)(i)(l));
			}
		}
		//COUT(F(h));
	}


	/**
	 * \brief Calculate the probability of moulting vs carapace width.
	 * \details Note that the parameters molt_mu and molt cv can only be
	 * estimated in cases where there is new shell and old shell data.
	 * 
	 * Note that the diagonal of the P matrix != 0, otherwise the matrix
	 * is singular in inv(P).
	 */
FUNCTION calc_molting_probability
	int l,h;
	molt_probability.initialize();
	P.initialize();
	double tiny = 0.000;
	for( h = 1; h <= nsex; h++ )
	{
		dvariable mu = molt_mu(h);
		dvariable sd = mu* molt_cv(h);
		molt_probability(h) = 1.0 - ((1.0-2.*tiny)*plogis(mid_points,mu,sd) + tiny);
		for( l = 1; l <= nclass; l++ )
		{
			P(h)(l,l) = molt_probability(h)(l);
		}
	}


	/**
	 * @brief calculate size distribution for new recuits.
	 * @details Based on the gamma distribution, calculates the probability
	 * of a new recruit being in size-interval size.
	 * 
	 * TODO: fix the scale on cumd_gamma distribution so beta rbeta is estimable.
	 * 
	 * @param ra is the mean of the distribution.
	 * @param rbeta scales the variance of the distribution
	 */
FUNCTION calc_recruitment_size_distribution
	
	dvariable ralpha = ra / rbeta;
	dvar_vector x(1,nclass+1);
	for(int l = 1; l <= nclass+1; l++ )
	{
		x(l) = cumd_gamma(size_breaks(l)/rbeta,ralpha);
	}
	rec_sdd  = first_difference(x);
	rec_sdd /= sum(rec_sdd);   // Standardize so each row sums to 1.0


	/**
	 * @brief initialiaze populations numbers-at-length in syr
	 * @author Steve Martell
	 * @details This function initializes the populations numbers-at-length
	 * in the initial year of the model.  
	 * 
	 * Psuedocode:  See note from Dave Fournier.
	 * 
	 * For the initial numbers-at-lengt a vector of deviates is estimated,
	 * one for each size class, and have the option to initialize
	 * the model at unfished equilibrium, or some other steady state condition.
	 *  
	 *  Dec 11, 2014. Martell & Ianelli at snowgoose.  We had a discussion regarding
	 *  how to deal with the joint probability of molting and growing to a new size
	 *  interval for a given length, and the probability of not molting.  We settled 
	 *  on using the size-tranistion matrix to represent this joint probability, where
	 *  the diagonal of the matrix to represent the probability of surviving and 
	 *  molting to a new size interval. The upper diagonal of the size-transition matrix
	 *  represent the probability of growing to size interval j' given size interval j.
	 *  
	 *  Oldshell crabs are then the column vector of 1-molt_probabiltiy times the 
	 *  numbers-at-length, and the Newshell crabs is the column vector of molt_probability
	 *  times the number-at-length.
	 *  
	 *  Jan 1, 2015.  Changed how the equilibrium calculation is done.  Use a numerical
	 *  approach to solve the newshell oldshell initial abundance.
	 *  
	 *  Jan 3, 2015.  Working with John Levitt on analytical solution instead of the 
	 *  numerical approach.  Think we have a soln.  
	 *  
	 *  Notation:
	 *      n = vector of newshell crabs
	 *      o = vector of oldshell crabs
	 *      P = diagonal matrix of molting probabilities by size
	 *      S = diagonal matrix of survival rates by size
	 *      A = Size transition matrix.
	 *      r = vector of new recruits (newshell)
	 *      I = identity matrix.
	 *  
	 *  The following equations represent the dynamics of newshell and oldshell crabs.
	 *      n = nSPA + oSPA + r                     (1)
	 *      o = oS(I-P)A + nS(I-P)A                 (2)
	 *  Objective is to solve the above equations for n and o repsectively.  Starting
	 *  with o:
	 *      o = n(I-P)S[I-(I-P)S]^(-1)              (3)
	 *  next substitute (3) into (1) and solve for n
	 *      n = nPSA + n(I-P)S[I-(I-P)S]^(-1)PSA + r
	 *  
	 *  let B = [I-(I-P)S]^(-1)
	 *      
	 *      n - nPSA - n(I-P)SBPSA = r
	 *      n(I - PSA - (I-P)SBPSA) = r
	 *  
	 *  let C = (I - PSA - (I-P)SBPSA)
	 *  
	 *  then n = C^(-1) r                           (4)
	 *  –––-—————————————————————————————————————————————————————————————————————————----
	 * 
	 *  April 28, 2015.  There is no case here for initializing the model at unfished
	 *  equilibrium conditions.  Need to fix this for SRA purposes.  SJDM. 
	 */
FUNCTION calc_initial_numbers_at_length
	dvariable log_initial_recruits;
	//N.initialize();
	d3_newShell.initialize();
	d3_oldShell.initialize();

	// Initial recrutment.
	if ( bInitializeUnfished )
	{
		log_initial_recruits = logR0;
	}
	else
	{
		log_initial_recruits = logRini;
	}
	recruits(syr) = exp(log_initial_recruits);
	dvar_vector rt = 1.0/nsex * recruits(syr) * rec_sdd;

	// Analytical equilibrium soln.
	int ig;
	d3_N.initialize();
	dmatrix Id = identity_matrix(1,nclass);
	dvar_vector  x(1,nclass);
	dvar_vector  y(1,nclass);
	dvar_matrix  A(1,nclass,1,nclass);
	dvar_matrix _S(1,nclass,1,nclass);
	_S.initialize();


	for(int h = 1; h <= nsex; h++ )
	{
		A = growth_transition(h);
		
		// Unfished conditions
		if ( bInitializeUnfished )
		{
			for(int i = 1; i <= nclass; i++ )
			{
				_S(i,i) = exp(-M(h)(syr)(i));
			}
		}
		// Steady-state fished conditions
		else
		{
			_S = S(h)(syr);
		}

		// Single shell condition
		if ( nshell == 1 && nmature == 1 )
		{
			calc_equilibrium(x,A,_S,rt);
			ig = pntr_hmo(h,1,1);
			d3_N(ig)(syr) = elem_prod(x , exp(rec_ini));
		}

		// Continuous molt (newshell/oldshell)
		if ( nshell == 2 && nmature == 1 )
		{
			calc_equilibrium(x,y,A,_S,P(h),rt);
			ig = pntr_hmo(h,1,1);
			d3_N(ig)(syr)   = elem_prod(x , exp(rec_ini));;
			d3_N(ig+1)(syr) = elem_prod(y , exp(rec_ini));;
		}

		// Insert terminal molt case here.


	}
	
	if(verbose == 1) COUT(d3_N(1)(syr));
	// cout<<"End of calc_initial_numbers_at_length"<<endl; 
	

	/**
	 * @brief Update numbers-at-length
	 * @author Team
	 * @details  Numbers at length are propagated each year for each sex based on the 
	 * size transition matrix and a vector of size-specifc survival rates. The columns
	 * of the size-transition matrix are multiplied by the size-specific survival rate
	 * (a sclaer).  New recruits are added based on the estimated aveerage recruitment and 
	 * annual deviate, multiplied by a vector of size-proportions (rec_sdd).
	 */
FUNCTION update_population_numbers_at_length
	int h,i,ig,o,m;

	dmatrix Id = identity_matrix(1,nclass); 
	dvar_vector rt(1,nclass);
	dvar_vector  x(1,nclass);
	dvar_vector  y(1,nclass);
	
	dvar_matrix t1(1,nclass,1,nclass);
	dvar_matrix  A(1,nclass,1,nclass);
	dvar_matrix At(1,nclass,1,nclass);
	if ( bInitializeUnfished )
	{
		recruits(syr+1,nyr) = mfexp(logR0);
	}
	else
	{
		recruits(syr+1,nyr) = mfexp(logRbar);	
	}

	for( i = syr; i <= nyr; i++ )
	{
		if( i > syr )
		{
			recruits(i) *= mfexp(rec_dev(i));
		}
		rt = (1.0/nsex * recruits(i)) * rec_sdd;

		for( ig = 1; ig <= n_grp; ig++ )
		{
			h = isex(ig);
			m = imature(ig);
			o = ishell(ig);
			
			if( o == 1 )    // newshell
			{
				A  = growth_transition(h) * S(h)(i);
				x = d3_N(ig)(i);
				d3_N(ig)(i+1) = elem_prod(x,diagonal(P(h))) * A + rt;
			
			}

			if( o == 2 )    // oldshell
			{
				x  = d3_N(ig)(i);
				y  = d3_N(ig-1)(i);
				t1 = (Id - P(h)) * S(h)(i);
				
				// add oldshell non-terminal molts to newshell
				d3_N(ig-1)(i+1) += elem_prod(x,diagonal(P(h))) * A;
				
				// oldshell
				d3_N(ig)(i+1) = (x+d3_N(ig-1)(i)) * t1;
			}

			if ( o == 1 && m == 2 )     // terminal molt to new shell.
			{

			}

			if ( o == 2 && m == 2 )     // terminal molt newshell to oldshell.
			{

			}

		}
	}
	if(verbose  == 1) COUT(d3_N(1)+d3_N(2));


	/**
	 * @brief Calculate stock recruitment relationship.
	 * @details  Assuming a Beverton-Holt relationship between the 
	 * mature biomass (user defined) and the annual recruits.  Note 
	 * that we derive so and bb in R = so * MB / (1 + bb * Mb)
	 * from Ro and steepness (leading parameters defined in theta).
	 *
	 * NOTES:
	 * if nSRR_flag == 1 then use a Beverton-Holt model to compute the 
	 * recruitment deviations for minimization.
	 * 
	 */
FUNCTION calc_stock_recruitment_relationship
	dvariable so, bb;
	dvariable ro = mfexp(logR0);
	dvariable phiB;
	dvariable reck = 4.*steepness/(1.-steepness);
	dvar_matrix _A(1,nclass,1,nclass);
	dvar_matrix _S(1,nclass,1,nclass);
	_A.initialize();
	_S.initialize();

	// get unfished mature male biomass per recruit.
	phiB = 0.0;
	for(int h = 1; h <= nsex; h++ )
	{
		for (int l = 1; l <= nclass; ++l)
		{
			_S(l,l) = exp(-M(h)(syr)(l));
		}
		_A = growth_transition(h);
		dvar_vector x(1,nclass);
		dvar_vector y(1,nclass);

		double lam;
		h <= 1 ? lam = spr_lambda: lam = (1.0 - spr_lambda);

		// Single shell condition
		if ( nshell == 1 && nmature == 1)
		{
			calc_equilibrium(x,_A,_S,rec_sdd);
			phiB += lam * x * elem_prod(mean_wt(h),maturity(h));
		}

		// Continuous molt (newshell/oldshell)
		if ( nshell == 2 && nmature == 1)
		{
			calc_equilibrium(x,y,_A,_S,P(h),rec_sdd);
			phiB += lam * x * elem_prod(mean_wt(h),maturity(h))
			     +  lam * y * elem_prod(mean_wt(h),maturity(h));
		}

		// Insert terminal molt case here.


	}
	dvariable bo = ro * phiB;

	so   = reck * ro / bo;
	bb   = (reck -1.0 ) / bo;

	dvar_vector ssb  = calc_ssb().shift(syr+1);
	dvar_vector rhat = elem_div(so * ssb , 1.0 + bb* ssb);
	
	// residuals
	int byr = syr+1;
	res_recruit.initialize();
	dvariable sigR = mfexp(logSigmaR);
	dvariable sig2R = 0.5 * sigR * sigR;

	switch(nSRR_flag)
	{
		case 0: // NO SRR
			//res_recruit(syr)     = log(recruits(syr)) - logRbar;
			res_recruit(byr,nyr) = log(recruits(byr,nyr))
			                       - (1.0-rho) * logRbar
			                       - rho * log(++recruits(byr-1,nyr-1))
			                       + sig2R;
		break;

		case 1:	// SRR model
			//xi(byr,nyr) = log(recruits(byr,nyr)) - log(rhat(byr,nyr)) + sig2R;
			res_recruit(byr,nyr) = log(recruits(byr,nyr))
			                       - (1.0-rho) * log(rhat(byr,nyr))
			                       - rho * log(++recruits(byr-1,nyr-1))
			                       + sig2R;
		break;
	}
	

	/**
	 * @brief Calculate predicted catch observations
	 * @details The function uses the Baranov catch equation to predict the retained
	 * and discarded catch.
	 * 
	 * Assumptions:
	 *  1) retained (landed catch) is assume to be newshell male only.
	 *  2) discards are all females (new and old) and male only crab.
	 *  3) Natural and fishing mortality occur simultaneously.
	 *  4) discard is the total number of crab caught and discarded.
	 * 
	 * @param  [description]
	 * @return NULL
	 */
FUNCTION calc_predicted_catch
	int h,i,j,k,ig;
	int type,unit;
	pre_catch.initialize();
	dvariable tmp_ft;
	dvar_vector sel(1,nclass);
	dvar_vector nal(1,nclass);      // numbers or biomass at length.
	
	for(int kk = 1; kk <= nCatchDF; kk++ )
	{
		for( j = 1; j <= nCatchRows(kk); j++ )
		{   
			i = dCatchData(kk,j,1);        // year index
			k = dCatchData(kk,j,3);        // gear index
			h = dCatchData(kk,j,4);        // sex index

			// Type of catch (retained = 1, discard = 2)
			type = int(dCatchData(kk,j,7));

			// Units of catch equation (1 = biomass, 2 = numbers)
			unit = int(dCatchData(kk)(j,8));
			
			// Total catch
			if(h)   // sex specific
			{
				nal.initialize();
				sel = log_slx_capture(k)(h)(i);
				switch(type)
				{
					case 1:     // retained catch
						// question here about what the retained catch is.
						// Should probably include shell condition here as well.
						// Now assuming both old and new shell are retained.
						sel = exp( sel + log_slx_retaind(k)(h)(i) );
						for(int m = 1; m <= nmature; m++ )
						{   
							for(int o = 1; o <= nshell; o++ )
							{
								ig   = pntr_hmo(h,m,o); 
								nal += d3_N(ig)(i);
							}
						}
					break;

					case 2:     // discard catch
						sel = elem_prod(exp(sel),1.0 - exp( log_slx_retaind(k)(h)(i) ));
						for(int m = 1; m <= nmature; m++ )
						{
							for(int o = 1; o <= nshell; o++ )
							{
								ig   = pntr_hmo(h,m,o);
								nal += d3_N(ig)(i);
							}
						}
					break;
				}
				tmp_ft = ft(k)(h)(i);
				nal = (unit==1) ? elem_prod(nal,mean_wt(h)) : nal;

				pre_catch(kk,j) = nal * elem_div( elem_prod(tmp_ft*sel,1.0-exp(-Z(h)(i))), Z(h)(i) );
			}
			else    // sexes combibed
			{
				for( h = 1; h <= nsex; h++ )
				{
					nal.initialize();
					sel = log_slx_capture(k)(h)(i);
					switch(type)
					{
						case 1:     // retained catch
							sel = exp( sel + log_slx_retaind(k)(h)(i) );
							for(int m = 1; m <= nmature; m++ )
							{
								ig   = pntr_hmo(h,m,1); //indexes new shell.
								nal += d3_N(ig)(i);
							}
						break;

						case 2:     // discard catch
							sel = 
								elem_prod(exp(sel),1.0 - exp( log_slx_retaind(k)(h)(i) ));
							//COUT(sel)
							for(int m = 1; m <= nmature; m++ )
							{
								for(int o = 1; o <= nshell; o++ )
								{
									ig   = pntr_hmo(h,m,o);
									nal += d3_N(ig)(i);
								}
							}
						break;
					}
					tmp_ft = ft(k)(h)(i);
					nal = (unit==1) ? elem_prod(nal,mean_wt(h)) : nal;

					pre_catch(kk,j) += nal * elem_div(elem_prod(tmp_ft*sel,1.0-exp(-Z(h)(i))),Z(h)(i));
				}
			}
		}
		// Catch residuals
		//COUT(pre_catch(kk));
		res_catch(kk) = log(obs_catch(kk)) - log(pre_catch(kk));
		if(verbose == 1)COUT(pre_catch(kk)(1));
	}


	/**
	 * @brief Calculate predicted relative abundance and residuals
	 * @author Steve Martell
	 * 
	 * @details This function uses the conditional mle for q to scale
	 * the population to the relative abundance index.  Assumed errors in 
	 * relative abundance are lognormal.  Currently assumes that the CPUE
	 * index is made up of both retained and discarded crabs.
	 * 
	 * question regarding use of shell condition in the relative abundance index.
	 * Currenlty there is no shell condition information in the CPUE data, should
	 * there be? Similarly, there is no mature immature information, should there be?
	 * 
	 */
FUNCTION calc_relative_abundance
	int g,h,i,j,k,ig;
	int unit;
	dvar_vector nal(1,nclass);  // numbers at length
	dvar_vector sel(1,nclass);  // selectivity at length

	for( k = 1; k <= nSurveys; k++ )
	{
		dvar_vector V(1,nSurveyRows(k));    
		V.initialize();
		for( j = 1; j <= nSurveyRows(k); j++ )
		{
			nal.initialize();
			i = dSurveyData(k)(j)(1);       // year index
			g = dSurveyData(k)(j)(3);       // gear index
			h = dSurveyData(k)(j)(4);       //  sex index
			unit = dSurveyData(k)(j)(7);    // units 1==biomass 2==Numbers

			if(h)
			{
				sel = exp(log_slx_capture(g)(h)(i));
				for(int m = 1; m <= nmature; m++ )
				{
					for(int o = 1; o <= nshell; o++ )
					{
						ig   = pntr_hmo(h,m,o);
						nal +=  (unit==1)? 
								elem_prod(d3_N(ig)(i),mean_wt(h)):
								d3_N(ig)(i);
					}
				}

				V(j) = nal * sel;
			}
			else
			{
				for( h = 1; h <= nsex; h++ )
				{
					sel = exp(log_slx_capture(g)(h)(i));
					for(int m = 1; m <= nmature; m++ )
					{
						for(int o = 1; o <= nshell; o++ )
						{
							ig   = pntr_hmo(h,m,o);
							nal +=  (unit==1)? 
									elem_prod(d3_N(ig)(i),mean_wt(h)): 
									d3_N(ig)(i);
						}
					}
					
					V(j) += nal * sel;
				}
			}
		} // nSurveyRows(k)
		dvar_vector zt = log(obs_cpue(k)) - log(V);
		dvariable zbar = mean(zt);
		res_cpue(k)    = zt - zbar;
		survey_q(k)    = mfexp(zbar);
	  if (active( q_dev )&& k==1) // OjO	
	  {
	  	dvar_vector delta(2,nSurveyRows(k));
	  	delta.initialize();
	  	delta = get_delta(q_type,2,nSurveyRows(k),q_dev,q_nodeyear,q_nNodes);
	  	dvariable qtmp ;
	  	qtmp = survey_q(k);
		  pre_cpue(k,1)    = qtmp * V(1);
	  	for (i=2;i<=nSurveyRows(1);i++)
	  	{
	  	  qtmp *= exp(delta(i));
		    pre_cpue(k,i)    = qtmp * V(i);
	  	}
		  res_cpue(k)    = log(obs_cpue(k)) - log(pre_cpue(k));
	  }	
	  else
		  pre_cpue(k)    = survey_q(k) * V;
	}


	/**
	 * @brief Calculate predicted size composition data.
         *
	 * @details Predicted size composition data are given in proportions.
	 * Size composition strata:
	 *  - sex  (0 = both sexes, 1 = male, 2 = female)
	 *  - type (0 = all catch, 1 = retained, 2 = discard)
	 *  - shell condition (0 = all, 1 = new shell, 2 = oldshell)
	 *  - mature or immature (0 = both, 1 = immature, 2 = mature)
	 * 
	 * NB Sitting in a campground on the Orgeon Coast writing this code,
	 * with baby Tabitha sleeping on my back.
	 * 
	 * TODO: 
	 *  - add pointers for shell type.   DONE
	 *  - add pointers for maturity state. DONE
	 *  - need pointer for retained vs. discarded.
	 *  
	 *  Jan 5, 2015.
	 *  Size compostion data can come in a number of forms.
	 *  Given sex, maturity and 3 shell conditions, there are 12 possible
	 *  combinations for adding up the numbers at length (nal).
	 *                          Shell
	 *    Sex     Maturity        condition   Description
	 *    _____________________________________________________________
	 *    Male    0               1           immature, new shell
	 * !  Male    0               2           immature, old shell
	 * !  Male    0               0           immature, new & old shell               1               Male, immature, new shell
	 *    Male    1               1             mature, new shell
	 *    Male    1               2             mature, old shell
	 *    Male    1               0             mature, new & old shell
	 *  Female    0               1           immature, new shell
	 * !Female    0               2           immature, old shell
	 * !Female    0               0           immature, new & old shell
	 *  Female    1               1             mature, new shell
	 *  Female    1               2             mature, old shell
	 *  Female    1               0             mature, new & old shell
	 *    _____________________________________________________________
	 *  
	 *  Call function to get the appropriate numbers-at-length.
	 *  
	 *  TODO:
	 *  [x] Check to ensure new shell old shell is working.
	 *  [ ] Add maturity component for data sets with mature old and mature new.
	 *  [ ] Issue 53, comps/total(sex,shell cond) 
	 */
FUNCTION calc_predicted_composition
	int h,i,j,k,ig;
	int type,shell,bmature ;
	d3_pre_size_comps.initialize();
	dvar_vector dNtmp(1,nclass);
	dvar_vector dNtot(1,nclass);
	dvar_vector   nal(1,nclass);

	for(int ii = 1; ii <= nSizeComps; ii++ )
	{
		for(int jj = 1; jj <= nSizeCompRows(ii); jj++ )
		{
			dNtmp.initialize();
			dNtot.initialize();
			nal.initialize();
			i        = d3_SizeComps(ii)(jj,-7);     // year
			j        = d3_SizeComps(ii)(jj,-6);     // seas
			k        = d3_SizeComps(ii)(jj,-5);     // gear
			h        = d3_SizeComps(ii)(jj,-4);     // sex
			type     = d3_SizeComps(ii)(jj,-3);     // retained or discard
			shell    = d3_SizeComps(ii)(jj,-2);     // shell condition
			bmature  = d3_SizeComps(ii)(jj,-1);     // boolean for maturity
				
			
			if(h) // sex specific
			{
				dvar_vector sel = exp(log_slx_capture(k)(h)(i));
				dvar_vector ret = exp(log_slx_retaind(k)(h)(i));
				dvar_vector dis = exp(log_slx_discard(k)(h)(i));
				// dvar_vector tmp = N(h)(i);

				for(int m = 1; m <= nmature; m++ )
				{
					for(int o = 1; o <= nshell; o++ )
					{
						ig   = pntr_hmo(h,m,o);
						if(shell == 0) nal += d3_N(ig)(i);
						if(shell == o) nal += d3_N(ig)(i);
					}
				}
				dvar_vector tmp = nal;
				
				switch (type)
				{
					case 1:     // retained
						dNtmp = elem_prod(tmp,elem_prod(sel,ret));
					break;
					case 2:     // discarded
						dNtmp = elem_prod(tmp,elem_prod(sel,dis));
					break;
					default:	// both retained and discarded
						dNtmp = elem_prod(tmp,sel);
					break;
				}

			}
			else // sexes combined in the observations
			{
				for( h = 1; h <= nsex; h++ )
				{
					dvar_vector sel = exp(log_slx_capture(k)(h)(i));
					dvar_vector ret = exp(log_slx_retaind(k)(h)(i));
					dvar_vector dis = exp(log_slx_discard(k)(h)(i));
					// dvar_vector tmp = N(h)(i);

					for(int m = 1; m <= nmature; m++ )
					{
						for(int o = 1; o <= nshell; o++ )
						{
							ig   = pntr_hmo(h,m,o);
							if(shell == 0) nal += d3_N(ig)(i);
							if(shell == o) nal += d3_N(ig)(i);
						}
					}
					dvar_vector tmp = nal;

					switch (type)
					{
						case 1:
							dNtmp += elem_prod(tmp,ret);
						break;
						case 2:
							dNtmp += elem_prod(tmp,dis);
						break;
						default:
							dNtmp += elem_prod(tmp,sel);
						break;
					}
				}
			}
			d3_pre_size_comps(ii)(jj) = dNtmp / sum(dNtmp);
		}
		
	}


FUNCTION dvariable get_prior_pdf(const int &pType, const dvariable &theta, const double &p1, const double &p2)
	{
		dvariable prior_pdf;
		switch(pType)
			{
				// uniform
				case 0: 
					if ( (p2-p1) > 0 )
					{
						prior_pdf = -log(1.0 / (p2-p1));
					}
					else
					{
						cerr <<"Error in uniform prior, p1 > p2.\n";
						ad_exit(1);
					}
				break;

				// normal
				case 1:
					// COUT(p1);COUT(p2);
					prior_pdf = dnorm(theta,p1,p2);
					// COUT(prior_pdf);
				break;

				// lognormal
				case 2:
					prior_pdf = dlnorm(theta,log(p1),p2);
				break;

				// beta
				case 3:
					//lb = theta_control(i,2);
					//ub = theta_control(i,3);
					//prior_pdf = dbeta((theta-lb)/(ub-lb),p1,p2);
					prior_pdf = dbeta(theta,p1,p2);
				break;

				// gamma
				case 4:
					prior_pdf = dgamma(theta,p1,p2);
				break;
			}

			return prior_pdf;
	}


	/**
	 * @brief Calculate prior density functions for le // OjO	ading parameters.
	 * @details 
	 *  - case 0 is a uniform density between the lower and upper bounds.
	 *  - case 1 is a normal density with mean = p1 and sd = p2
	 *  - case 2 is a lognormal density with mean = log(p1) and sd = p2
	 *  - case 3 is a beta density bounded between lb-ub with p1 and p2 as alpha & beta
	 *  - case 4 is a gamma density with parameters p1 and p2.
	 *  
	 *  TODO
	 *  Make this a generic function.
	 *  Agrs would be vector of parameters, and matrix of controls
	 *  @param theta a vector of parameters
	 *  @param C matrix of controls (priorType, p1, p2, lb, ub)
	 *  @return vector of prior densities for each parameter
	 *  
	 */
FUNCTION calculate_prior_densities
	double p1,p2;
	double lb,ub;
	priorDensity.initialize();
	
	for(int i = 1; i <= ntheta; i++ )
	{
		if( active(theta(i) ))
		{
			int priorType = int(theta_control(i,5));
			p1 = theta_control(i,6);
			p2 = theta_control(i,7);
			dvariable x = theta(i);
			if(priorType == 3)
			{
				lb = theta_control(i,2);
				ub = theta_control(i,3);
				x  = (x-lb)/(ub-lb);
			}

			priorDensity(i) = get_prior_pdf(priorType,x,p1,p2);
		}
	}

	for(int i = 1; i <= nGrwth; i++ )
	{
		if( active(Grwth(i)) )
		{

			int priorType = int(Grwth_control(i,5));
			p1 = Grwth_control(i,6);
			p2 = Grwth_control(i,7);
			dvariable x = Grwth(i);
			if(priorType == 3)
			{
				lb = Grwth_control(i,2);
				ub = Grwth_control(i,3);
				x  = (x-lb)/(ub-lb);
			}

			priorDensity(ntheta+i) = get_prior_pdf(priorType,x,p1,p2);
		}
	}

	// ---Continue with catchability priors-----------------------
	int iprior = ntheta + nGrwth + 1; 
	for (int k=1;k<=nSurveys;k++)
	{
		int itype = int(prior_qtype(k));
		switch(itype)
		{
			// Analytical soln, no prior (uniform, uniformative)
			case 0:
			break;
			// Prior on analytical soln, log-normal
			case 1:
				priorDensity(iprior) = dnorm(log(survey_q(k)),log(prior_qbar(k)),prior_qsd(k));
			break;
		}
		iprior++;
	}


	/**
	 * @brief calculate objective function
	 * @details 
	 * 
	 * Likelihood components
	 *  -# likelihood of the catch data (assume lognormal error)
	 *  -# likelihood of relative abundance data
	 *  -# likelihood of size composition data
	 * 
	 * Penalty components
	 *  -# Penalty on log_fdev to ensure they sum to zero.
	 *  -# Penalty to regularize values of log_fbar.
	 *  -# Penalty to constrain random walk in natural mortaliy rates
	 */
FUNCTION calc_objective_function
	// |---------------------------------------------------------------------------------|
	// | NEGATIVE LOGLIKELIHOOD COMPONENTS FOR THE OBJECTIVE FUNCTION                    |
	// |---------------------------------------------------------------------------------|
	nloglike.initialize();
	
	// 1) Likelihood of the catch data.
	if(verbose == 1) COUT(res_catch(1));
	for(int k = 1; k <= nCatchDF; k++ )
	{
		dvector catch_sd = sqrt(log(1.0 + square(catch_cv(k))));
		nloglike(1,k) += dnorm(res_catch(k),catch_sd);
	}

	// 2) Likelihood of the relative abundance data.
  if(verbose == 1) COUT(res_cpue(1));
	for(int k = 1; k <= nSurveys; k++ )
	{
		dvector cpue_sd = sqrt(log(1.0 + square(cpue_cv(k))));
		nloglike(2,k) += cpue_lambda(k) * dnorm(res_cpue(k),cpue_sd(k));
	}

	// 3) Likelihood for size composition data. 
	for(int ii = 1; ii <= nSizeComps; ii++)
	{
		dmatrix     O = d3_obs_size_comps(ii);
		dvar_matrix P = d3_pre_size_comps(ii);
		dvar_vector log_effn  = log(exp(log_vn(ii)) * size_comp_sample_size(ii));
		d3_res_size_comps.initialize();

		bool bCmp = bTailCompression(ii);
		acl::negativeLogLikelihood *ploglike;
		
		switch(nAgeCompType(ii))
		{
			case 0:  // ignore composition data in model fitting.
				ploglike = NULL;
			break;
			case 1:  // multinomial with fixed or estimated n
				ploglike = new acl::multinomial(O,bCmp);
			break;

			case 2:  // robust approximation to the multinomial
				if( current_phase() <= 3 || !last_phase() )
					ploglike = new acl::multinomial(O,bCmp);
				else
					ploglike = new acl::robust_multi(O,bCmp);
			break;
		}
		// Compute residuals in the last phase.
		if( last_phase() && ploglike != NULL ) 
		{
		  d3_res_size_comps(ii) = ploglike->residual(log_effn,P);
		}

		// now compute the likelihood.
		if(ploglike != NULL)
		{
			nloglike(3,ii) += ploglike->nloglike(log_effn,P);			
		}
	}

	// 4) Likelihood for recruitment deviations.
	if( active(rec_dev) )
	{
		dvariable sigR = mfexp(logSigmaR);
		switch(nSRR_flag)
		{
			case 0:  
				//nloglike(4,1)  = dnorm(rec_dev,sigR);
				nloglike(4,1)  = dnorm(res_recruit,sigR);
				nloglike(4,1) += dnorm(rec_ini,sigR);
			break;

			case 1:
				nloglike(4,1)  = dnorm(res_recruit,sigR);
			break;
		}
		
	}

	// 5) Likelihood for growth increment data
	if( !bUseEmpiricalGrowth && ( active(Grwth(1)) || active(Grwth(2)) ) )
	{
		dvar_vector MoltIncPred = calc_growth_increments(dPreMoltSize, iMoltIncSex);
		nloglike(5,1)    = dnorm(log(dMoltInc) - log(MoltIncPred),dMoltIncCV);
	}


	// |---------------------------------------------------------------------------------|
	// | PENALTIES AND CONSTRAINTS                                                       |
	// |---------------------------------------------------------------------------------|
	nlogPenalty.initialize();

	// 1) Penalty on log_fdev to ensure they sum to zero 
	for(int k = 1; k <= nfleet; k++ )
	{
		dvariable s     = mean(log_fdev(k));
		nlogPenalty(1) += 10000.0*s*s;
		dvariable r     = mean(log_fdov(k));
		nlogPenalty(1) += 10000.0*r*r;
	}

	// 2) Penalty on mean F to regularize the solution.
	int irow=1;
	if(last_phase()) irow=2;
	dvariable fbar;
	dvariable log_fbar;
	for(int k = 1; k <= nfleet; k++ )
	{
		fbar = mean( ft(k)(1) );
		if( pen_fbar(k) > 0  && fbar != 0 )
		{
			log_fbar = log(fbar);
			nlogPenalty(2) += dnorm(log_fbar,log(pen_fbar(k)),pen_fstd(irow,k));			
		}
	}

	// 3) Penalty to constrain M in random walk
	if( active(m_dev) )
		nlogPenalty(3) = dnorm(m_dev,m_stdev);
		// Need to change gmr table_penalties function
	if( active(q_dev) )
		nlogPenalty(4) = dnorm(q_dev,q_stdev);

	// 4 Penalty on recruitment devs.
	if( active(rec_dev) && nSRR_flag !=0)
		nlogPenalty(5) = dnorm(rec_dev,1.0);
	if( active(rec_ini) && nSRR_flag !=0)
		nlogPenalty(6) = dnorm(rec_ini,1.0);
	if( active(rec_dev))
		nlogPenalty(7) = dnorm(first_difference(rec_dev),1.0);

	objfun = sum(nloglike) + sum(nlogPenalty) + sum(priorDensity);
	if( verbose==2 ) 
	{
		COUT(objfun);
		COUT(nloglike);
		COUT(nlogPenalty);
		COUT(priorDensity);
	}


	/**
	 * @brief Simulation model
	 * @details Uses many of the same routines as the assessment
	 * model, over-writes the observed data in memory with simulated 
	 * data.
	 */
FUNCTION simulation_model
	// random number generator
	random_number_generator rng(rseed);
	
	// Initialize model parameters
	initialize_model_parameters();

	// Fishing fleet dynamics ...
	calc_selectivities();
	calc_fishing_mortality();

	
	dvector drec_dev(syr+1,nyr);
	drec_dev.fill_randn(rng);
	rec_dev = exp(logSigmaR) * drec_dev;

	// Population dynamics ...
	calc_growth_increments();
	calc_molting_probability();
	calc_growth_transition();
	calc_natural_mortality();
	calc_total_mortality();
	calc_recruitment_size_distribution();
	calc_initial_numbers_at_length();
	update_population_numbers_at_length();

	// observation models ...
	calc_predicted_catch();
	calc_relative_abundance();
	calc_predicted_composition();

	
	// add observation errors to catch.
	dmatrix err_catch(1,nCatchDF,1,nCatchRows);
	err_catch.fill_randn(rng);
	dmatrix catch_sd(1,nCatchDF,1,nCatchRows);
	for(int k = 1; k <= nCatchDF; k++ )
	{
		catch_sd(k)  = sqrt(log(1.0 + square(catch_cv(k))));
		obs_catch(k) = value(pre_catch(k));
		err_catch(k) = elem_prod(catch_sd(k),err_catch(k)) - 0.5*square(catch_sd(k));
		obs_catch(k) = elem_prod(obs_catch(k),exp(err_catch(k)));
	}
	

	// add observation errors to cpue. & fill in dSurveyData column 5
	dmatrix err_cpue(1,nSurveys,1,nSurveyRows);
	dmatrix cpue_sd = sqrt(log(1.0 + square(cpue_cv)));
	err_cpue.fill_randn(rng);
	obs_cpue = value(pre_cpue);
	err_cpue = elem_prod(cpue_sd,err_cpue) - 0.5*square(cpue_sd);
	obs_cpue = elem_prod(obs_cpue,exp(err_cpue));
	for(int k = 1; k <= nSurveys; k++ )
	{
		for(int i = 1; i <= nSurveyRows(k); i++ )
		{
			dSurveyData(k)(i,5) = obs_cpue(k,i);
		}
	}
	

	// add sampling errors to size-composition.
	// 3darray d3_obs_size_comps(1,nSizeComps,1,nSizeCompRows,1,nSizeCompCols);
	double tau;
	for(int k = 1; k <= nSizeComps; k++ )
	{
		for(int i = 1; i <= nSizeCompRows(k); i++ )
		{
			tau = sqrt(1.0 / size_comp_sample_size(k)(i));
			dvector p = value(d3_pre_size_comps(k)(i)); 
			d3_obs_size_comps(k)(i) = rmvlogistic(p,tau,rseed+k+i);
		}
	}
	// COUT(d3_pre_size_comps(1)(1));
	// COUT(d3_obs_size_comps(1)(1));


REPORT_SECTION
	dvector mod_yrs(syr,nyr); 
	mod_yrs.fill_seqadd(syr,1);
	REPORT(name_read_flt);
	REPORT(name_read_srv);
	REPORT(mod_yrs);
	REPORT(mid_points); 
	REPORT(nloglike);
	REPORT(nlogPenalty);
	REPORT(priorDensity);
	REPORT(dCatchData);
	REPORT(obs_catch);
	REPORT(pre_catch);
	REPORT(res_catch);
	REPORT(dSurveyData);
	REPORT(obs_cpue);
	REPORT(pre_cpue);
	REPORT(res_cpue);

	report << "slx_capture"<<endl;
	for (int i=syr;i<=nyr;i++) for (int h=1;h<=nsex;h++) for (int j=1;j<=nfleet;j++)
		report << i << " " << h << " " << j << " " << exp(log_slx_capture(j,h,i)) <<endl;
	report << "slx_retaind"<<endl;
	for (int i=syr;i<=nyr;i++) for (int h=1;h<=nsex;h++) for (int j=1;j<=nfleet;j++)
		report << i << " " << h << " " << j << " " << exp(log_slx_retaind(j,h,i)) <<endl;
	report << "slx_discard"<<endl;
	for (int i=syr;i<=nyr;i++) for (int h=1;h<=nsex;h++) for (int j=1;j<=nfleet;j++)
		report << i << " " << h << " " << j << " " << exp(log_slx_discard(j,h,i)) <<endl;

	REPORT(slx_control);
	REPORT(log_slx_capture);
	REPORT(log_slx_retaind);
	REPORT(log_slx_discard);
	
	REPORT(F);
	REPORT(d3_SizeComps);

	REPORT(d3_obs_size_comps);
	REPORT(d3_pre_size_comps);
	REPORT(d3_res_size_comps);
	REPORT(ft);
	REPORT(rec_sdd);
	
	REPORT(rec_ini);
	REPORT(rec_dev);
	REPORT(recruits);
	REPORT(xi);
	REPORT(d3_N);
	REPORT(M);
	REPORT(Z);
	REPORT(mean_wt);
	REPORT(molt_probability);	///> vector of molt probabilities

	dvector ssb = value(calc_ssb());
	REPORT(ssb);

	if(last_phase())
	{
		int refyear = nyr-1;
		calc_spr_reference_points(refyear,spr_fleet);
		//calc_ofl(refyear,spr_fspr);
		REPORT(spr_fspr);
		REPORT(spr_bspr);
		REPORT(spr_rbar);
		REPORT(spr_fofl);
		REPORT(spr_cofl);
		REPORT(spr_ssbo);

		dvar_matrix mean_size(1,nsex,1,nclass);
		///>  matrix to get distribution of size at say, nclass "ages" (meaning years since initial recruitment)
		dvar3_array growth_matrix(1,nsex,1,nclass,1,nclass);
		for (int isex=1;isex<=nsex;isex++)
		{
			int iage=1;
			// Set the initial size frequency
			growth_matrix(isex,iage) = growth_transition(isex,iage);
			mean_size(isex,iage)     = growth_matrix(isex,iage) * mid_points /sum(growth_matrix(isex,iage));
			for (iage=2;iage<=nclass;iage++)
			{
				growth_matrix(isex,iage) = growth_matrix(isex,iage-1)*growth_transition(isex);
				mean_size(isex,iage)     = growth_matrix(isex,iage) * mid_points / sum(growth_matrix(isex,iage));
			}
		}
		REPORT(growth_matrix);
		REPORT(mean_size);
		for(int ii = 1; ii <= nSizeComps; ii++)
		{
			// Set final sample-size for composition data for comparisons
			size_comp_sample_size(ii) = value(exp(log_vn(ii))) * size_comp_sample_size(ii);
		}
		REPORT(size_comp_sample_size);
	}
	// Print total numbers at length
	dvar_matrix N_len(syr,nyr+1,1,nclass);
	dvar_matrix N_mm(syr,nyr+1,1,nclass);
	dvar_matrix N_males(syr,nyr+1,1,nclass);
	dvar_matrix N_males_old(syr,nyr+1,1,nclass);
	N_len.initialize();
	N_males.initialize();
	N_mm.initialize();
	N_males_old.initialize();
	for (int i=syr;i<=nyr+1;i++)
	  for (int j=1;j<=nclass;j++)
	    for (int k=1;k<=n_grp;k++)
	    {	
	    	if (isex(k)==1)
	    	{
	    		N_males(i,j) += d3_N(k,i,j);
					if (ishell(k)==2)
		    		N_males_old(i,j) += d3_N(k,i,j);
					if (imature(k)==1)
		    		N_mm(i,j) += d3_N(k,i,j);
	    	}
	    	N_len(i,j) += d3_N(k,i,j);
	    }

	
	REPORT(N_len);
	REPORT(N_mm);
	REPORT(N_males);
	REPORT(N_males_old);
	REPORT(molt_increment);
	REPORT(dPreMoltSize);
	REPORT(iMoltIncSex);
	REPORT(dMoltInc);
	if(bUseEmpiricalGrowth)
	{
		dvector pMoltInc = dMoltInc;
		REPORT(pMoltInc);
	}
	else
	{
		dvar_vector pMoltInc = calc_growth_increments(dPreMoltSize,iMoltIncSex);
		REPORT(pMoltInc);
	}
	REPORT(survey_q);
	
	// Growth and size transition.
	REPORT(P);
	REPORT(growth_transition);
	d3_array tG(1,nsex,1,nclass,1,nclass);
	d3_array tS(1,nsex,1,nclass,1,nclass);

	for(int h = 1; h<=nsex; h++)
	{
		tG(h)=trans(value(growth_transition(h)));
		tS(h)=trans(value(P(h) * growth_transition(h)));
		for(int l = 1; l <= nclass; ++l)
		{
			tS(h)(l,l) += value(1.0-P(h)(l,l));
		}
	}
	REPORT(tG);
	REPORT(tS);
	dmatrix size_transition_M(1,nclass,1,nclass);
	dmatrix size_transition_F(1,nclass,1,nclass);

	// For Jim's r-script.
	size_transition_M = value(P(1) * growth_transition(1));
	for (int i=1;i<=nclass;i++)
	{
	  size_transition_M(i,i) += value(1.-P(1,i,i));
	}

	REPORT(size_transition_M);
	
	if (nsex==2)
	{
	  	size_transition_F = value(P(2) * growth_transition(2));
  		for (int i=1;i<=nclass;i++)
		{
			    size_transition_M(i,i) += value(1.-P(2,i,i));
		}
		REPORT(size_transition_F);
	}


	/**
	 * @brief Calculate spawning stock biomass (SSB)
	 * @details Calculation of the mature male biomass is based on the
	 * numbers-at-length summed over each shell condition.
	 * 
	 * TODO correct for timing of when the SSB is calculated
	 * Add female component if lamnda < 1
	 * 
	 * @return dvar_vector ssb (model mature biomass).
	 */
FUNCTION dvar_vector calc_ssb()
	dvar_vector ssb(syr,nyr);
	ssb.initialize();
	int ig,m,o;
	int h = 1; // males
	for(int i = syr; i <= nyr; i++ )
	{
		for( ig = 1; ig <= n_grp; ig++ )
		{
			h = isex(ig);
			o = ishell(ig);
			m = imature(ig);
			double lam;
			h <= 1 ? lam = spr_lambda: lam = (1.0 - spr_lambda);
			ssb(i) += lam * d3_N(ig)(i) * elem_prod(mean_wt(h),maturity(h));
		}
	}
	return(ssb);


	/**
	 * @brief calculate spr-based reference points.
	 * @details Calculate the SPR-ratio for a given value of F.
	 * 
	 * Psuedocode:
	 *  -# calculate average recruitment over reference period.
	 *  -# compute the ratio of F's based on reference year (nyr)
	 *  -# calculate fishing mortality vector.
	 *  -# calculate equibrium total mortality vector.
	 *  -# calculate growth/survival transition matrix.
	 *  
	 *  ARGS:
	 *  @param iyr Reference year for selectivity and fishing mortality ratios
	 *  @param ifleet index for gear to compute SPR values, other fleets with const F
	 *  
	 *  got response from andre, “The convention is to fix F for all 
	 *  non-directed fisheries to a recent average and to solve for 
	 *  the F for the directed fishery so that you achieve B35%.” but 
	 *  I think he meant F35
	 *  
	 *  Use bisection method to find SPR_target.
	 *  
	 *  Three possible states
	 *  nshell = 1,
	 *  nshell = 2 && nmaturity = 1,
	 *  nshell = 2 && nmaturity = 2.
	 */
FUNCTION void calc_spr_reference_points(const int iyr,const int ifleet)
	// Average recruitment
	spr_rbar =  mean(value(recruits(spr_syr,spr_nyr)));

	double   _r = spr_rbar;
	dvector _rx = value(rec_sdd);
	d3_array _M(1,nsex,1,nclass,1,nclass);
	_M.initialize();
	dmatrix _N(1,nsex,1,nclass);
	dmatrix _wa(1,nsex,1,nclass);
	d3_array _A = value(growth_transition);
	d3_array _P = value(P);
	for(int h = 1; h <= nsex; h++ )
	{
		for(int l = 1; l <= nclass; l++ )
		{
			_M(h)(l,l) = value(M(h)(iyr)(l));
		}
		//todo fix me.
		_N(h) = value(d3_N(1)(iyr));
		_wa(h) = elem_prod(mean_wt(h),maturity(h));
	}
	
	dmatrix  _fhk(1,nsex,1,nfleet);
	d3_array _sel(1,nsex,1,nfleet,1,nclass);
	d3_array _ret(1,nsex,1,nfleet,1,nclass);
	for(int h = 1; h <= nsex; h++ )
	{
		for(int k=1;k<=nfleet;k++)
		{
			_fhk(h)(k) = value(ft(k)(h)(iyr));
			_sel(h)(k) = exp(value(log_slx_capture(k)(h)(iyr)));
			_ret(h)(k) = exp(value(log_slx_retaind(k)(h)(iyr)));
		}
	}

	// Discard Mortality rates
	dvector  _dmr(1,nfleet);
	_dmr.initialize();
	for(int k = 1; k <= nfleet; k++ )
	{
		_dmr(k) = dmr(iyr,k);
	}
	

	//spr *ptrSPR=nullptr;
	spr *ptrSPR=0;

	
	// SPR reference points for a single shell condition.
	if(nshell == 1)
	{
		spr c_spr(_r,spr_lambda,_rx,_wa,_M,_A);
		ptrSPR = &c_spr;
	}
	// SPR reference points for new and old shell condition.
	if(nshell == 2)
	{
		spr c_spr(_r,spr_lambda,_rx,_wa,_M,_P,_A);
		ptrSPR = &c_spr;    
	}
	spr_fspr = ptrSPR->get_fspr(ifleet,spr_target,_fhk,_sel,_ret,_dmr);
	spr_bspr = ptrSPR->get_bspr();
	spr_ssbo = ptrSPR->get_ssbo();

	// OFL Calculations
	dvector ssb = value(calc_ssb());
	double cuttoff = 0.1;
	double limit = 0.25;
	spr_fofl = ptrSPR->get_fofl(cuttoff,limit,ssb(nyr));
	spr_cofl = ptrSPR->get_cofl(_N);


RUNTIME_SECTION
  maximum_function_evaluations 500,   500,   1500,  25000, 25000
  convergence_criteria         1.e-2, 1.e-2, 1.e-3, 1.e-4, 1.e-4, 


GLOBALS_SECTION
	/**
	 * @file gmacs.cpp
	 * @authors Steve Martell and Jim Ianelli
	 */

	#include <admodel.h>
	#include <time.h>
	//#include "./test/comm.h"
	//#include <contrib.h>
	#if defined __APPLE__ || defined __linux
	#include "./include/libgmacs.h"
	#endif

	#if defined _WIN32 || defined _WIN64
	#include "include\libgmacs.h"
	#endif

	time_t start,finish;
	long hour,minute,second;
	double elapsed_time;

	// Define objects for report file, echoinput, etc.
	/**
	\def report(object)
	Prints name and value of \a object on ADMB report %ofstream file.
	*/
	#undef REPORT
	#define REPORT(object) report << #object "\n" << setw(8) \
	<< setprecision(4) << setfixed() << object << endl;

	/**
	 *
	 * \def COUT(object)
	 * Prints object to screen during runtime.
	 * cout <<setw(6) << setprecision(3) << setfixed() << x << endl;
	 */
	 #undef COUT
	 #define COUT(object) cout << #object "\n" << setw(6) \
	 << setprecision(3) << setfixed() << object << endl;

	#undef MAXIT
	#undef TOL
	#define MAXIT 100
	#define TOL 1.0e-4

	/**
	\def ECHO(object)
	Prints name and value of \a object on echoinput %ofstream file.
	*/
	 #undef ECHO
	 #define ECHO(object) echoinput << #object << "\n" << object << endl;

  /**
	\def WriteFileName(object)
	Prints name and value of \a object on control %ofstream file.
	*/
	 #undef WriteFileName
	 #define WriteFileName(object) ECHO(object); gmacs_files << "# " << #object << "\n" << object << endl;

  /**
	\def WriteCtl(object)
	Prints name and value of \a object on control %ofstream file.
	*/
	 #undef WriteCtl
	 #define WriteCtl(object) ECHO(object); gmacs_ctl << "# " << #object << "\n" << object << endl;

  /**
	\def WRITEDAT(object)
	Prints name and value of \a object on data %ofstream file.
	*/
	 #undef WRITEDAT
	 #define WRITEDAT(object) ECHO(object); gmacs_data << "# " << #object << "\n" << object << endl;
 
	 // Open output files using ofstream
	 // This one for easy reading all input to R
	 ofstream echoinput("checkfile.rep");
	 // These ones for compatibility with ADMB (# comment included)
	 ofstream gmacs_files("gmacs_files_in.dat");
	 ofstream  gmacs_data("gmacs_in.dat");
	 ofstream   gmacs_ctl("gmacs_in.ctl");



TOP_OF_MAIN_SECTION
	time(&start);
	arrmblsize = 50000000;
	gradient_structure::set_GRADSTACK_BUFFER_SIZE(1.e7);
	gradient_structure::set_CMPDIF_BUFFER_SIZE(1.e7);
	gradient_structure::set_MAX_NVAR_OFFSET(5000);
	gradient_structure::set_NUM_DEPENDENT_VARIABLES(5000);
	gradient_structure::set_MAX_DLINKS(150000);


FINAL_SECTION
	//  Print run time statistics to the screen.
	time(&finish);
	elapsed_time=difftime(finish,start);
	hour=long(elapsed_time)/3600;
	minute=long(elapsed_time)%3600/60;
	second=(long(elapsed_time)%3600)%60;
	cout<<endl<<endl<<"*******************************************"<<endl;
	cout<<endl<<endl<<"-------------------------------------------"<<endl;
	cout<<"--Start time: "<<ctime(&start)<<endl;
	cout<<"--Finish time: "<<ctime(&finish)<<endl;
	cout<<"--Runtime: ";
	cout<<hour<<" hours, "<<minute<<" minutes, "<<second<<" seconds"<<endl;
	cout<<"--Number of function evaluations: "<<nf<<endl;
	cout<<"*******************************************"<<endl;
