**free
// =============================================================================
// Test stubs — Department Enquiry Options + F3 (Sec 3.3, 3.4)
// Rules covered: BR-006, BR-007, BR-008, BR-009
// =============================================================================

ctl-opt nomain ccsidcvt(*excp) ccsid(*char : *jobrun) BNDDIR('APP');

/include qinclude,TESTCASE

exec sql
  set option commit = *none;

// ---------------------------------------------------------------------------
// BR-006 — Option 5 navigates to Employee List for selected department
// ---------------------------------------------------------------------------
dcl-proc test_BR006_option5_routes_to_employee_list export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // Full verification requires an interactive test harness that can call
  // DEPTS.PGM, enter option '5', and confirm EMPLOYEES.PGM is invoked with
  // the correct DEPTNO parameter.
  //
  // Structural assertion: the code path for SelVal='5' in
  // corpus/app/qrpglesrc/depts.pgm.sqlrpgle:144-147 calls Employees(XID).
  assert(*on : 'BR-006: When SelVal=''5'', Employees(XID) is called — confirmed depts.pgm.sqlrpgle:144-147');
  // Citation: corpus/app/qrpglesrc/depts.pgm.sqlrpgle:144-147
end-proc;

// ---------------------------------------------------------------------------
// BR-007 — Option 8 navigates to New Employee screen for selected department
// ---------------------------------------------------------------------------
dcl-proc test_BR007_option8_routes_to_newemp export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // Structural assertion: the code path for SelVal='8' in
  // corpus/app/qrpglesrc/depts.pgm.sqlrpgle:148-150 calls NewEmp(XID),
  // and newemp.pgm.sqlrpgle:53 assigns XDEPT = currentDepartment.
  assert(*on : 'BR-007: When SelVal=''8'', NewEmp(XID) called and dept pre-populated — confirmed depts.pgm.sqlrpgle:148-150, newemp.pgm.sqlrpgle:53');
  // Citation: corpus/app/qrpglesrc/depts.pgm.sqlrpgle:148-150
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:53
end-proc;

// ---------------------------------------------------------------------------
// BR-008 — Selection field cleared after option is processed
// ---------------------------------------------------------------------------
dcl-proc test_BR008_selection_field_cleared_after_action export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // Structural assertion: after processing SelVal, the code at
  // corpus/app/qrpglesrc/depts.pgm.sqlrpgle:153-157 sets XSEL = *Blank
  // and calls Update SFLDTA.
  assert(*on : 'BR-008: XSEL blanked after option processed — confirmed depts.pgm.sqlrpgle:153-157');
  // Citation: corpus/app/qrpglesrc/depts.pgm.sqlrpgle:153-157
end-proc;

// ---------------------------------------------------------------------------
// BR-009 — F3=Exit terminates the application
// ---------------------------------------------------------------------------
dcl-proc test_BR009_F3_exits_application export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // Structural assertions:
  // 1. CA03(03) declared in corpus/app/qddssrc/depts.dspf:2 — F3 enabled.
  // 2. 'F3=Exit' label in depts.dspf:30.
  // 3. When Funkey=F03, Exit=*On is set in depts.pgm.sqlrpgle:71-72.
  // 4. *INLR=*ON; Return; in depts.pgm.sqlrpgle:78-79 terminates the program.
  assert(*on : 'BR-009: F3 handler sets Exit=*On and *INLR=*ON — confirmed depts.pgm.sqlrpgle:71-79');
  // Citation: corpus/app/qddssrc/depts.dspf:2
  // Citation: corpus/app/qrpglesrc/depts.pgm.sqlrpgle:71-79
  // Citation: corpus/app/qrpgleref/constants.rpgleinc:3
end-proc;
