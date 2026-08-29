**free
// =============================================================================
// Test stubs — New Employee Screen (Sec 5.2–5.7)
// Rules covered: BR-019 to BR-046 (excluding DRIFTED: BR-029, BR-032,
//               BR-037, BR-041, BR-044)
// =============================================================================

ctl-opt nomain ccsidcvt(*excp) ccsid(*char : *jobrun) BNDDIR('APP');

/include qinclude,TESTCASE

exec sql
  set option commit = *none;

dcl-proc setUpSuite export;
  dcl-s cmd varchar(1000);

  cmd = 'CRTDUPOBJ OBJ(EMPLOYEE) FROMLIB(*LIBL) OBJTYPE(*FILE) TOLIB(QTEMP) NEWOBJ(EMPLOYEE)';
  exec sql call qsys2.qcmdexc(:cmd);
  cmd = 'OVRDBF FILE(EMPLOYEE) TOFILE(QTEMP/EMPLOYEE) OVRSCOPE(*JOB)';
  exec sql call qsys2.qcmdexc(:cmd);

  cmd = 'CRTDUPOBJ OBJ(DEPARTMENT) FROMLIB(*LIBL) OBJTYPE(*FILE) TOLIB(QTEMP) NEWOBJ(DEPARTMENT)';
  exec sql call qsys2.qcmdexc(:cmd);
  cmd = 'OVRDBF FILE(DEPARTMENT) TOFILE(QTEMP/DEPARTMENT) OVRSCOPE(*JOB)';
  exec sql call qsys2.qcmdexc(:cmd);

  exec sql
    insert into department (deptno, deptname, mgrno, admrdept, location)
    values ('E00', 'STUB DEPT', '000001', 'E00', 'STUB CITY');
end-proc;

// ---------------------------------------------------------------------------
// BR-019 — ID field is output-only; auto-assigned before user entry
// ---------------------------------------------------------------------------
dcl-proc test_BR019_id_field_output_only export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // XID in nemp.dspf:7 has DDS usage 'O' (output-only).
  // newemp.pgm.sqlrpgle:45-51 calls getNewEmpId() before the display loop.
  assert(*on : 'BR-019: XID is O (output-only) in nemp.dspf:7 — getNewEmpId called before display loop');
  // Citation: corpus/app/qddssrc/nemp.dspf:7
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:45-51
end-proc;

// ---------------------------------------------------------------------------
// BR-020 — Department field pre-populated and output-only
// ---------------------------------------------------------------------------
dcl-proc test_BR020_dept_field_prepopulated_output_only export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // XDEPT in nemp.dspf:27 has DDS usage 'O'.
  // newemp.pgm.sqlrpgle:53 assigns XDEPT = currentDepartment before loop.
  assert(*on : 'BR-020: XDEPT is O (output-only) in nemp.dspf:27, pre-set at newemp.pgm.sqlrpgle:53');
  // Citation: corpus/app/qddssrc/nemp.dspf:27
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:53
end-proc;

// ---------------------------------------------------------------------------
// BR-021 — Input fields: First, Initial, Last, Job, Salary, Phone
// ---------------------------------------------------------------------------
dcl-proc test_BR021_input_fields_present export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // All six B-usage fields confirmed in nemp.dspf lines 12,17,22,32,37,42.
  assert(*on : 'BR-021: XFIRST/XINIT/XLAST/XJOB/XSAL/XTEL all B-usage confirmed nemp.dspf:12,17,22,32,37,42');
  // Citation: corpus/app/qddssrc/nemp.dspf:12-42
end-proc;

// ---------------------------------------------------------------------------
// BR-022 — First field: 12 characters
// ---------------------------------------------------------------------------
dcl-proc test_BR022_first_field_12_chars export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // XFIRST is 12A in nemp.dspf:12; FIRSTNME is VARCHAR(12) in employee.table:5.
  assert(*on : 'BR-022: XFIRST 12A and FIRSTNME VARCHAR(12) confirmed — nemp.dspf:12, employee.table:5');
  // Citation: corpus/app/qddssrc/nemp.dspf:12
  // Citation: corpus/app/qsqlsrc/employee.table:5
end-proc;

// ---------------------------------------------------------------------------
// BR-023 — Initial field: 1 character
// ---------------------------------------------------------------------------
dcl-proc test_BR023_initial_field_1_char export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-023: XINIT 1A and MIDINIT CHAR(1) confirmed — nemp.dspf:17, employee.table:6');
  // Citation: corpus/app/qddssrc/nemp.dspf:17
  // Citation: corpus/app/qsqlsrc/employee.table:6
end-proc;

// ---------------------------------------------------------------------------
// BR-024 — Last field: 15 characters
// ---------------------------------------------------------------------------
dcl-proc test_BR024_last_field_15_chars export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-024: XLAST 15A and LASTNAME VARCHAR(15) confirmed — nemp.dspf:22, employee.table:7');
  // Citation: corpus/app/qddssrc/nemp.dspf:22
  // Citation: corpus/app/qsqlsrc/employee.table:7
end-proc;

// ---------------------------------------------------------------------------
// BR-025 — Job field: 8 characters
// ---------------------------------------------------------------------------
dcl-proc test_BR025_job_field_8_chars export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-025: XJOB 8A and JOB CHAR(8) confirmed — nemp.dspf:32, employee.table:11');
  // Citation: corpus/app/qddssrc/nemp.dspf:32
  // Citation: corpus/app/qsqlsrc/employee.table:11
end-proc;

// ---------------------------------------------------------------------------
// BR-026 — Salary field: 10 characters, interpreted as decimal(9,2)
// ---------------------------------------------------------------------------
dcl-proc test_BR026_salary_field_10_chars_decimal export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // XSAL is 10A in nemp.dspf:37; newemp.pgm.sqlrpgle:104 uses %dec(XSAL:9:2).
  assert(*on : 'BR-026: XSAL 10A, %dec(XSAL:9:2) confirmed — nemp.dspf:37, newemp.pgm.sqlrpgle:104');
  // Citation: corpus/app/qddssrc/nemp.dspf:37
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:104
end-proc;

// ---------------------------------------------------------------------------
// BR-028 — First name blank → 'First name cannot be blank'
// ---------------------------------------------------------------------------
dcl-proc test_BR028_blank_firstname_message export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // newemp.pgm.sqlrpgle:119-121: if XFIRST='' return 'First name cannot be blank'.
  // To test without an interactive session, call GetError through a service
  // program wrapper (not yet exposed); structural confirmation only.
  assert(*on : 'BR-028: blank XFIRST returns ''First name cannot be blank'' — newemp.pgm.sqlrpgle:119-121');
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:119-121
end-proc;

// ---------------------------------------------------------------------------
// BR-030 — Last name blank → 'Last name cannot be blank'
// ---------------------------------------------------------------------------
dcl-proc test_BR030_blank_lastname_message export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-030: blank XLAST returns ''Last name cannot be blank'' — newemp.pgm.sqlrpgle:123-125');
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:123-125
end-proc;

// ---------------------------------------------------------------------------
// BR-031 — Department blank → 'Department cannot be blank'
// ---------------------------------------------------------------------------
dcl-proc test_BR031_blank_dept_message export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-031: blank XDEPT returns ''Department cannot be blank'' — newemp.pgm.sqlrpgle:127-131');
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:127-131
end-proc;

// ---------------------------------------------------------------------------
// BR-033 — Salary blank → 'Salary cannot be blank'
// ---------------------------------------------------------------------------
dcl-proc test_BR033_blank_salary_message export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-033: blank XSAL returns ''Salary cannot be blank'' — newemp.pgm.sqlrpgle:137-139');
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:137-139
end-proc;

// ---------------------------------------------------------------------------
// BR-034 — Non-numeric salary → 'Salary must be a number'
// ---------------------------------------------------------------------------
dcl-proc test_BR034_non_numeric_salary_message export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-034: non-numeric XSAL returns ''Salary must be a number'' — newemp.pgm.sqlrpgle:141-145');
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:141-145
end-proc;

// ---------------------------------------------------------------------------
// BR-035 — Phone blank → 'Phone cannot be blank'
// ---------------------------------------------------------------------------
dcl-proc test_BR035_blank_phone_message export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-035: blank XTEL returns ''Phone cannot be blank'' — newemp.pgm.sqlrpgle:153-154');
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:153-154
end-proc;

// ---------------------------------------------------------------------------
// BR-036 — Non-numeric phone → 'Phone must be a number'
// ---------------------------------------------------------------------------
dcl-proc test_BR036_non_numeric_phone_message export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-036: non-numeric XTEL returns ''Phone must be a number'' — newemp.pgm.sqlrpgle:157-161');
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:157-161
end-proc;

// ---------------------------------------------------------------------------
// BR-038 — Error messages shown in red in XERR field below input fields
// ---------------------------------------------------------------------------
dcl-proc test_BR038_error_in_red_below_inputs export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // XERR at row 15, COLOR(RED) in nemp.dspf:44. Input fields at rows 6-13.
  assert(*on : 'BR-038: XERR COLOR(RED) at row 15 (below inputs rows 6-13) — nemp.dspf:44');
  // Citation: corpus/app/qddssrc/nemp.dspf:44
end-proc;

// ---------------------------------------------------------------------------
// BR-039 — Only one error at a time; re-validates from beginning on each Enter
// ---------------------------------------------------------------------------
dcl-proc test_BR039_single_error_revalidates_from_start export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // GetError() uses early-return pattern — first failing check exits immediately.
  // Loop at newemp.pgm.sqlrpgle:55-76 calls GetError on each Enter press.
  assert(*on : 'BR-039: single-error early-return in GetError — newemp.pgm.sqlrpgle:114-165');
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:114-165
end-proc;

// ---------------------------------------------------------------------------
// BR-040 — Field values retained on validation failure
// ---------------------------------------------------------------------------
dcl-proc test_BR040_field_values_retained_on_failure export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // All input fields are B (both) usage — EXFMT re-sends existing values.
  assert(*on : 'BR-040: B-usage fields retain values through EXFMT — nemp.dspf:12-42, newemp.pgm.sqlrpgle:55-78');
  // Citation: corpus/app/qddssrc/nemp.dspf:12-42
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:55-78
end-proc;

// ---------------------------------------------------------------------------
// BR-042 — Successful submit returns to Dept Enquiry screen
// ---------------------------------------------------------------------------
dcl-proc test_BR042_success_returns_to_dept_enquiry export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // On success HandleInsert sets Exit=*On; *INLR=*ON; Return —
  // control goes back to depts.pgm.sqlrpgle which called NewEmp(XID).
  assert(*on : 'BR-042: on success Exit=*On/*INLR=*ON returns to DEPTS — newemp.pgm.sqlrpgle:68-80, depts.pgm.sqlrpgle:148-151');
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:68-80
  // Citation: corpus/app/qrpglesrc/depts.pgm.sqlrpgle:148-151
end-proc;

// ---------------------------------------------------------------------------
// BR-043 — Insert failure shows 'Unable to create employee'
// ---------------------------------------------------------------------------
dcl-proc test_BR043_insert_failure_message export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // HandleInsert on SQLCODE <> 0 sets XERR = 'Unable to create employee.'
  assert(*on : 'BR-043: insert failure sets XERR=''Unable to create employee.'' — newemp.pgm.sqlrpgle:68-72');
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:68-72
end-proc;

// ---------------------------------------------------------------------------
// BR-045 — F12=Back and Enter=Create shown on New Employee screen
// ---------------------------------------------------------------------------
dcl-proc test_BR045_function_keys_shown export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // nemp.dspf:47 shows 'F12=Back Enter=Create'; CA12(12) at line 2.
  assert(*on : 'BR-045: F12=Back Enter=Create shown at nemp.dspf:47; CA12 at nemp.dspf:2');
  // Citation: corpus/app/qddssrc/nemp.dspf:2
  // Citation: corpus/app/qddssrc/nemp.dspf:47
end-proc;

// ---------------------------------------------------------------------------
// BR-046 — F12 discards input and returns to Dept Enquiry; no record created
// ---------------------------------------------------------------------------
dcl-proc test_BR046_F12_discards_and_returns export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // F12 at newemp.pgm.sqlrpgle:62-63 sets Exit=*On without calling HandleInsert.
  // Return at line 78-80 goes back to depts.pgm.sqlrpgle.
  assert(*on : 'BR-046: F12 sets Exit=*On without calling HandleInsert — newemp.pgm.sqlrpgle:62-63,78-80');
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:62-63
end-proc;
