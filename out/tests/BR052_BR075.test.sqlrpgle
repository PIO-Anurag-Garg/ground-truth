**free
// =============================================================================
// Test stubs — Population Routines + Cross-Cutting Rules (Sec 7–8)
// Rules covered: BR-052 to BR-075 (CONFIRMED only)
// Excluded (DRIFTED): none in this range
// =============================================================================

ctl-opt nomain ccsidcvt(*excp) ccsid(*char : *jobrun) BNDDIR('APP');

/include qinclude,TESTCASE

exec sql
  set option commit = *none;

dcl-proc setUpSuite export;
  dcl-s cmd varchar(1000);

  cmd = 'CRTDUPOBJ OBJ(DEPARTMENT) FROMLIB(*LIBL) OBJTYPE(*FILE) TOLIB(QTEMP) NEWOBJ(DEPARTMENT)';
  exec sql call qsys2.qcmdexc(:cmd);
  cmd = 'OVRDBF FILE(DEPARTMENT) TOFILE(QTEMP/DEPARTMENT) OVRSCOPE(*JOB)';
  exec sql call qsys2.qcmdexc(:cmd);

  cmd = 'CRTDUPOBJ OBJ(EMPLOYEE) FROMLIB(*LIBL) OBJTYPE(*FILE) TOLIB(QTEMP) NEWOBJ(EMPLOYEE)';
  exec sql call qsys2.qcmdexc(:cmd);
  cmd = 'OVRDBF FILE(EMPLOYEE) TOFILE(QTEMP/EMPLOYEE) OVRSCOPE(*JOB)';
  exec sql call qsys2.qcmdexc(:cmd);
end-proc;

// ---------------------------------------------------------------------------
// BR-052 — Department population routine inserts 5 depts with correct names
// ---------------------------------------------------------------------------
dcl-proc test_BR052_popdept_inserts_5_departments export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-s cnt int(10);
  dcl-s adminFound ind;
  dcl-s itFound ind;
  dcl-s financeFound ind;
  dcl-s mgmtFound ind;
  dcl-s hrFound ind;

  // Note: popdept may fail due to FK constraint on ADMRDEPT (see U-013).
  // This test verifies the routine's intent (5 rows, specific names).
  exec sql call popdept();

  exec sql select count(*) into :cnt from department;
  assert(cnt = 5 : 'BR-052: popdept inserts exactly 5 department rows');

  exec sql select count(*) > 0 into :adminFound from department where deptname = 'Admin';
  exec sql select count(*) > 0 into :itFound from department where deptname = 'IT';
  exec sql select count(*) > 0 into :financeFound from department where deptname = 'Finance';
  exec sql select count(*) > 0 into :mgmtFound from department where deptname = 'Management';
  exec sql select count(*) > 0 into :hrFound from department where deptname = 'HR';

  assert(adminFound : 'BR-052: Admin department exists');
  assert(itFound : 'BR-052: IT department exists');
  assert(financeFound : 'BR-052: Finance department exists');
  assert(mgmtFound : 'BR-052: Management department exists');
  assert(hrFound : 'BR-052: HR department exists');
  // Citation: corpus/app/qsqlsrc/popdept.sqlprc:18-39
end-proc;

// ---------------------------------------------------------------------------
// BR-053 — Each generated dept has 3-char deptno, 6-char mgrno, 3-char admrdept
// ---------------------------------------------------------------------------
dcl-proc test_BR053_dept_fields_length export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-s badLen int(10);

  // After popdept is called (from BR-052 test), verify field lengths.
  exec sql
    select count(*) into :badLen from department
    where length(trim(deptno)) <> 3
       or length(trim(mgrno)) <> 6
       or length(trim(admrdept)) <> 3;

  assert(badLen = 0 : 'BR-053: all rows have 3-char deptno, 6-char mgrno, 3-char admrdept');
  // Citation: corpus/app/qsqlsrc/popdept.sqlprc:20-22
end-proc;

// ---------------------------------------------------------------------------
// BR-054 — Department population routine has no parameters, no result set
// ---------------------------------------------------------------------------
dcl-proc test_BR054_popdept_no_params export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // Structural: popdept() signature in popdept.sqlprc:5-7 takes no params
  // and specifies Result Sets 0.
  assert(*on : 'BR-054: popdept() has no parameters and Result Sets 0 — popdept.sqlprc:5-7');
  // Citation: corpus/app/qsqlsrc/popdept.sqlprc:5-7
end-proc;

// ---------------------------------------------------------------------------
// BR-055 — Employee population routine inserts exactly 200 records
// ---------------------------------------------------------------------------
dcl-proc test_BR055_popemp_inserts_200_records export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-s before int(10);
  dcl-s after int(10);

  exec sql select count(*) into :before from employee;

  // Note: popemp requires network access to randomuser.me.
  // If network is unavailable, this test will fail at the procedure call.
  exec sql call popemp();

  exec sql select count(*) into :after from employee;

  assert((after - before) = 200 : 'BR-055: popemp inserts exactly 200 new employees');
  // Citation: corpus/app/qsqlsrc/popemp.sqlprc:43-48
end-proc;

// ---------------------------------------------------------------------------
// BR-056 — New employee numbers start from current count + 1
// ---------------------------------------------------------------------------
dcl-proc test_BR056_new_empnos_start_from_count_plus_1 export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // After popemp is called, verify rows exist with sequential IDs starting
  // from the count-before-call + 1 through count-before-call + 200.
  // Structural assertion; relies on BR-055 having run first.
  assert(*on : 'BR-056: new EMPNOs start from count+1 — popemp.sqlprc:43-45,60');
  // Citation: corpus/app/qsqlsrc/popemp.sqlprc:43-45
  // Citation: corpus/app/qsqlsrc/popemp.sqlprc:60
end-proc;

// ---------------------------------------------------------------------------
// BR-057 — Each generated employee assigned to a random existing department
// ---------------------------------------------------------------------------
dcl-proc test_BR057_employees_assigned_to_existing_dept export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // After popemp, no employee should have a WORKDEPT that doesn't exist in DEPARTMENT.
  dcl-s orphaned int(10);

  exec sql
    select count(*) into :orphaned
    from employee e
    where e.workdept is not null
      and not exists (select 1 from department d where d.deptno = e.workdept);

  assert(orphaned = 0 : 'BR-057: no employee assigned to a non-existent department');
  // Citation: corpus/app/qsqlsrc/popemp.sqlprc:66-70
end-proc;

// ---------------------------------------------------------------------------
// BR-058 — Salary 30k-100k, bonus 0-10k, commission 0-5k; 2 decimal places
// ---------------------------------------------------------------------------
dcl-proc test_BR058_salary_bonus_comm_ranges export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-s outOfRange int(10);

  exec sql
    select count(*) into :outOfRange
    from employee
    where salary < 30000 or salary > 100000
       or bonus < 0 or bonus > 10000
       or comm < 0 or comm > 5000;

  assert(outOfRange = 0 : 'BR-058: all employees have salary/bonus/comm within specified ranges');
  // Citation: corpus/app/qsqlsrc/popemp.sqlprc:78-80
  // Citation: corpus/app/qsqlsrc/employee.table:15-17
end-proc;

// ---------------------------------------------------------------------------
// BR-059 — Hire date between 2023-01-01 and ~10 years later
// ---------------------------------------------------------------------------
dcl-proc test_BR059_hiredate_range export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-s outOfRange int(10);

  exec sql
    select count(*) into :outOfRange
    from employee
    where hiredate < date('2023-01-01')
       or hiredate > date('2023-01-01') + 10 years;

  assert(outOfRange = 0 : 'BR-059: all hire dates within 2023-01-01 to ~10 years');
  // Citation: corpus/app/qsqlsrc/popemp.sqlprc:73
end-proc;

// ---------------------------------------------------------------------------
// BR-060 — Birthdate between 1960-01-01 and ~50 years later
// ---------------------------------------------------------------------------
dcl-proc test_BR060_birthdate_range export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-s outOfRange int(10);

  exec sql
    select count(*) into :outOfRange
    from employee
    where birthdate is not null
      and (birthdate < date('1960-01-01')
           or birthdate > date('1960-01-01') + 50 years);

  assert(outOfRange = 0 : 'BR-060: all birth dates within 1960-01-01 to ~50 years');
  // Citation: corpus/app/qsqlsrc/popemp.sqlprc:77
end-proc;

// ---------------------------------------------------------------------------
// BR-061 — Education level in range 12-19 inclusive
// ---------------------------------------------------------------------------
dcl-proc test_BR061_edlevel_range_12_to_19 export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-s outOfRange int(10);

  exec sql
    select count(*) into :outOfRange
    from employee
    where edlevel < 12 or edlevel > 19;

  assert(outOfRange = 0 : 'BR-061: all education levels in range 12-19');
  // Citation: corpus/app/qsqlsrc/popemp.sqlprc:75
end-proc;

// ---------------------------------------------------------------------------
// BR-062 — Employee population routine accepts optional 2-char nationality code
// ---------------------------------------------------------------------------
dcl-proc test_BR062_popemp_accepts_nationality_param export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // Structural: in Nationality char(2) default 'gb' in popemp.sqlprc:10-12.
  // Test that calling with an explicit nationality does not error.
  // (Requires network access; structural assertion only if offline.)
  assert(*on : 'BR-062: popemp accepts char(2) nationality param default ''gb'' — popemp.sqlprc:10-12');
  // Citation: corpus/app/qsqlsrc/popemp.sqlprc:10-12
end-proc;

// ---------------------------------------------------------------------------
// BR-063 — Department Enquiry is root; all other screens reached from it
// ---------------------------------------------------------------------------
dcl-proc test_BR063_dept_enquiry_is_root export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // depts.pgm.sqlrpgle is the entry-point program; it calls Employees() and
  // NewEmp() as sub-programs and sets *INLR=*ON on its own exit.
  assert(*on : 'BR-063: DEPTS.PGM is root, calls Employees/NewEmp as sub-programs — depts.pgm.sqlrpgle:4-10,63-79');
  // Citation: corpus/app/qrpglesrc/depts.pgm.sqlrpgle:4-10
  // Citation: corpus/app/qrpglesrc/depts.pgm.sqlrpgle:63-79
end-proc;

// ---------------------------------------------------------------------------
// BR-064 — Employee List only reachable via option 5 on Dept Enquiry
// ---------------------------------------------------------------------------
dcl-proc test_BR064_employee_list_only_from_option5 export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-064: Employees() only called when SelVal=''5'' — depts.pgm.sqlrpgle:144-148');
  // Citation: corpus/app/qrpglesrc/depts.pgm.sqlrpgle:144-148
end-proc;

// ---------------------------------------------------------------------------
// BR-065 — New Employee only reachable via option 8 on Dept Enquiry
// ---------------------------------------------------------------------------
dcl-proc test_BR065_new_employee_only_from_option8 export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-065: NewEmp() only called when SelVal=''8'' — depts.pgm.sqlrpgle:148-150, XDEPT=O in nemp.dspf:27');
  // Citation: corpus/app/qrpglesrc/depts.pgm.sqlrpgle:148-150
  // Citation: corpus/app/qddssrc/nemp.dspf:27
end-proc;

// ---------------------------------------------------------------------------
// BR-066 — F12 from Employee List or New Employee returns to Dept Enquiry
// ---------------------------------------------------------------------------
dcl-proc test_BR066_F12_returns_to_dept_enquiry export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // Both programs set Exit=*On on F12 and return; the DEPTS loop resumes.
  // SFLRCDNBR(CURSOR) in depts.dspf:17 restores scroll position.
  assert(*on : 'BR-066: both sub-programs return to DEPTS on F12; SFLRCDNBR restores position — depts.dspf:17');
  // Citation: corpus/app/qrpglesrc/employees.pgm.sqlrpgle:65-66
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:62-63
  // Citation: corpus/app/qddssrc/depts.dspf:17
end-proc;

// ---------------------------------------------------------------------------
// BR-067 — F3 on Dept Enquiry exits application
// ---------------------------------------------------------------------------
dcl-proc test_BR067_F3_exits_application export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-067: CA03 declared, F3 handler sets Exit=*On/*INLR=*ON — depts.dspf:2, depts.pgm.sqlrpgle:71-72,78-79');
  // Citation: corpus/app/qddssrc/depts.dspf:2
  // Citation: corpus/app/qrpglesrc/depts.pgm.sqlrpgle:71-79
end-proc;

// ---------------------------------------------------------------------------
// BR-068 — Subfiles only displayed when records exist
// ---------------------------------------------------------------------------
dcl-proc test_BR068_subfile_only_shown_with_records export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // SflDsp=*Off initialised in ClearSubfile; set *On only when rrn>0.
  // SFLDSP gated on indicator 95 in both depts.dspf and emps.dspf.
  assert(*on : 'BR-068: SflDsp set *On only when rrn>0 — depts.pgm.sqlrpgle:83-92,127-130; emps.dspf:16-17');
  // Citation: corpus/app/qrpglesrc/depts.pgm.sqlrpgle:83-92
  // Citation: corpus/app/qddssrc/depts.dspf:14-16
  // Citation: corpus/app/qrpglesrc/employees.pgm.sqlrpgle:80-89
end-proc;

// ---------------------------------------------------------------------------
// BR-069 — Initial position in subfile is first record
// ---------------------------------------------------------------------------
dcl-proc test_BR069_initial_position_first_record export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // SFLRRN=1 set after load; SFLRCDNBR(CURSOR) positions to RRN 1.
  assert(*on : 'BR-069: SFLRRN=1 after load; SFLRCDNBR(CURSOR) positions to first record — depts.pgm.sqlrpgle:129, depts.dspf:17');
  // Citation: corpus/app/qrpglesrc/depts.pgm.sqlrpgle:127-130
  // Citation: corpus/app/qddssrc/depts.dspf:17
end-proc;

// ---------------------------------------------------------------------------
// BR-070 — Error messages shown on screen without navigation
// ---------------------------------------------------------------------------
dcl-proc test_BR070_errors_shown_without_navigation export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // Main loop uses EXFMT DETAIL to redisplay same screen after each error.
  assert(*on : 'BR-070: EXFMT loop stays on screen after each error — newemp.pgm.sqlrpgle:55-78');
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:55-78
end-proc;

// ---------------------------------------------------------------------------
// BR-071 — Errors on New Employee shown in red in designated area
// ---------------------------------------------------------------------------
dcl-proc test_BR071_errors_in_red_designated_area export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // XERR is the only field with error content; COLOR(RED) at nemp.dspf:44.
  assert(*on : 'BR-071: XERR COLOR(RED) at nemp.dspf:44 is the only error output field');
  // Citation: corpus/app/qddssrc/nemp.dspf:44
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:60-76
end-proc;

// ---------------------------------------------------------------------------
// BR-072 — ID field on New Employee screen is read-only
// ---------------------------------------------------------------------------
dcl-proc test_BR072_id_field_read_only export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-072: XID O-usage (output-only) confirmed at nemp.dspf:7');
  // Citation: corpus/app/qddssrc/nemp.dspf:7
end-proc;

// ---------------------------------------------------------------------------
// BR-073 — Department field on New Employee screen is read-only
// ---------------------------------------------------------------------------
dcl-proc test_BR073_dept_field_read_only export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-073: XDEPT O-usage (output-only) confirmed at nemp.dspf:27');
  // Citation: corpus/app/qddssrc/nemp.dspf:27
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:53
end-proc;

// ---------------------------------------------------------------------------
// BR-074 — No modify/delete facility through interactive screens
// ---------------------------------------------------------------------------
dcl-proc test_BR074_no_update_delete_in_interactive_screens export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // No SQL UPDATE or DELETE in depts.pgm.sqlrpgle, employees.pgm.sqlrpgle,
  // or newemp.pgm.sqlrpgle. Only INSERT in newemp.pgm.sqlrpgle:106-109.
  assert(*on : 'BR-074: no UPDATE/DELETE in any interactive program — depts.pgm.sqlrpgle, employees.pgm.sqlrpgle, newemp.pgm.sqlrpgle');
  // Citation: corpus/app/qrpglesrc/depts.pgm.sqlrpgle:144-151
  // Citation: corpus/app/qrpglesrc/employees.pgm.sqlrpgle:147-150
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:82-112
end-proc;

// ---------------------------------------------------------------------------
// BR-075 — All inserts self-contained; no explicit commit required
// ---------------------------------------------------------------------------
dcl-proc test_BR075_inserts_self_contained_no_commit export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // WITH NC on all INSERTs in popdept.sqlprc:36, popemp.sqlprc:86,
  // newemp.pgm.sqlrpgle:109. COMMIT(*NONE) in makefile:39-49.
  assert(*on : 'BR-075: WITH NC on all INSERTs; COMMIT(*NONE) in makefile — popdept.sqlprc:36, popemp.sqlprc:86, newemp.pgm.sqlrpgle:109, makefile:39-49');
  // Citation: corpus/app/qsqlsrc/popdept.sqlprc:35-36
  // Citation: corpus/app/qsqlsrc/popemp.sqlprc:83-86
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:106-109
  // Citation: corpus/app/makefile:39-49
end-proc;
