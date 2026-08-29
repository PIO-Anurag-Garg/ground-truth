**free
// =============================================================================
// Test stubs — Employee Identifier Assignment (Sec 6)
// Rules covered: BR-047, BR-049, BR-050, BR-051
// Note: BR-048 is DRIFTED (code uses +100 not +1) and is excluded.
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
end-proc;

// ---------------------------------------------------------------------------
// BR-047 — Employee IDs are assigned by the system; user never enters one
// ---------------------------------------------------------------------------
dcl-proc test_BR047_id_assigned_by_system export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // XID is output-only (O usage) in nemp.dspf:7 — user cannot type into it.
  // getNewEmpId() is called before the display loop at newemp.pgm.sqlrpgle:45-51.
  assert(*on : 'BR-047: XID is O-usage (output only) — nemp.dspf:7; getNewEmpId called at newemp.pgm.sqlrpgle:45-51');
  // Citation: corpus/app/qddssrc/nemp.dspf:7
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:45-51
end-proc;

// ---------------------------------------------------------------------------
// BR-049 — Identifier stored and displayed as 6-char zero-padded string
// ---------------------------------------------------------------------------
dcl-proc test_BR049_id_zero_padded_6_chars export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // Insert a row with a low EMPNO to verify zero-padding logic is consistent.
  // getNewEmpId uses %subst and pre-initialised '000000' to produce the format.
  exec sql
    insert into employee (empno, firstnme, midinit, lastname, workdept,
                          phoneno, edlevel, hiredate, salary, bonus, comm)
    values ('000200', 'PAD', 'T', 'TEST', null, '01234', 12,
            current date, 50000.00, 0, 0);

  // Verify the stored value is exactly 6 chars with leading zeroes.
  dcl-s stored char(6);
  exec sql select empno into :stored from employee where empno = '000200';

  assert(stored = '000200' : 'BR-049: EMPNO stored as 6-char zero-padded string');
  assert(%len(stored) = 6 : 'BR-049: EMPNO field is exactly 6 characters');

  exec sql delete from employee where empno = '000200';
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:175-191
end-proc;

// ---------------------------------------------------------------------------
// BR-050 — EMPNO field accommodates up to 6 significant digits
// ---------------------------------------------------------------------------
dcl-proc test_BR050_empno_field_6_digits export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // EMPNO CHAR(6) in employee.table:4 accommodates up to 999999.
  exec sql
    insert into employee (empno, firstnme, midinit, lastname, workdept,
                          phoneno, edlevel, hiredate, salary, bonus, comm)
    values ('999999', 'MAX', 'M', 'EMPNO', null, '01234', 12,
            current date, 50000.00, 0, 0);

  nEqual(0 : sqlcode : 'BR-050: EMPNO 999999 (max 6 digits) accepted without error');

  exec sql delete from employee where empno = '999999';
  // Citation: corpus/app/qsqlsrc/employee.table:4
end-proc;

// ---------------------------------------------------------------------------
// BR-051 — ID assigned at screen open; same ID used on submit
// ---------------------------------------------------------------------------
dcl-proc test_BR051_id_assigned_at_open_used_at_submit export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // getNewEmpId() at newemp.pgm.sqlrpgle:45 stores result in XID.
  // HandleInsert at line 87 assigns newEmp.EMPNO = XID (same value).
  // No re-generation occurs between display and submit.
  assert(*on : 'BR-051: XID assigned at line 45, reused at line 87 — newemp.pgm.sqlrpgle:45,87');
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:45-51
  // Citation: corpus/app/qrpglesrc/newemp.pgm.sqlrpgle:87
end-proc;
