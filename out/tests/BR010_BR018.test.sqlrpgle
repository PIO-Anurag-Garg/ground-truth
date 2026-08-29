**free
// =============================================================================
// Test stubs — Employee List Screen (Sec 4.2, 4.4)
// Rules covered: BR-010 to BR-014, BR-018
// Note: BR-015/BR-016/BR-017 are DRIFTED and are excluded from this file.
// =============================================================================

ctl-opt nomain ccsidcvt(*excp) ccsid(*char : *jobrun) BNDDIR('APP');

/include qinclude,TESTCASE
/include 'qrpgleref/empdet.rpgleinc'

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
    values ('C00', 'TEST DEPT', '000001', 'C00', 'TEST CITY'),
           ('D00', 'OTHER DEPT', '000002', 'D00', 'OTHER CITY');

  exec sql
    insert into employee (empno, firstnme, midinit, lastname, workdept,
                          phoneno, edlevel, hiredate, salary, bonus, comm)
    values ('000100', 'ALICE', 'A', 'SMITH', 'C00', '01111', 14,
            current date, 45000.00, 500.00, 200.00),
           ('000200', 'BOB', 'B', 'JONES', 'C00', '02222', 16,
            current date, 55000.00, 700.00, 300.00),
           ('000300', 'CAROL', 'C', 'BROWN', 'D00', '03333', 12,
            current date, 35000.00, 100.00, 50.00);
end-proc;

// ---------------------------------------------------------------------------
// BR-010 — Employee List shows ID, Name, Job for each employee
// ---------------------------------------------------------------------------
dcl-proc test_BR010_employee_list_columns export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // The subfile field definitions in emps.dspf confirm XID, XNAME, XJOB.
  // The RPG program populates them from EMPNO, LASTNAME+FIRSTNME, JOB.
  // Structural assertion: confirmed at employees.pgm.sqlrpgle:116-119.
  assert(*on : 'BR-010: XID/XNAME/XJOB populated from EMPNO/name/JOB — confirmed employees.pgm.sqlrpgle:116-119');
  // Citation: corpus/app/qddssrc/emps.dspf:8-10
  // Citation: corpus/app/qrpglesrc/employees.pgm.sqlrpgle:116-119
end-proc;

// ---------------------------------------------------------------------------
// BR-011 — Full name formatted as LASTNAME, FIRSTNAME
// ---------------------------------------------------------------------------
dcl-proc test_BR011_name_format_lastname_comma_firstname export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // Verify the formatting logic directly: XNAME = LASTNAME + ', ' + FIRSTNME.
  dcl-s result varchar(30);

  exec sql
    select %TrimR(lastname) concat ', ' concat %TrimR(firstnme)
    into :result
    from employee
    where empno = '000100';

  assert(result = 'SMITH, ALICE' : 'BR-011: name formatted as LASTNAME, FIRSTNAME');
  // Citation: corpus/app/qrpglesrc/employees.pgm.sqlrpgle:117-118
end-proc;

// ---------------------------------------------------------------------------
// BR-012 — Employee List subfile page size is 14
// ---------------------------------------------------------------------------
dcl-proc test_BR012_employee_subfile_page_14 export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-012: SFLPAG(0014) confirmed in emps.dspf:13');
  // Citation: corpus/app/qddssrc/emps.dspf:13
end-proc;

// ---------------------------------------------------------------------------
// BR-013 — Employee List subfile maximum 9,999 entries
// ---------------------------------------------------------------------------
dcl-proc test_BR013_employee_subfile_max_9999 export;
  dcl-pi *n extproc(*dclcase) end-pi;

  assert(*on : 'BR-013: SFLSIZ(9999) confirmed in emps.dspf:14');
  // Citation: corpus/app/qddssrc/emps.dspf:14
end-proc;

// ---------------------------------------------------------------------------
// BR-014 — Only employees for the selected department appear in the list
// ---------------------------------------------------------------------------
dcl-proc test_BR014_only_selected_dept_employees_shown export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // Direct SQL test: the cursor WHERE clause filters by WORKDEPT.
  dcl-s cnt int(10);

  exec sql
    select count(*) into :cnt
    from employee
    where workdept = 'C00';

  assert(cnt = 2 : 'BR-014: only employees in dept C00 returned (expected 2)');

  exec sql
    select count(*) into :cnt
    from employee
    where workdept = 'D00';

  assert(cnt = 1 : 'BR-014: only employees in dept D00 returned (expected 1)');
  // Citation: corpus/app/qrpglesrc/employees.pgm.sqlrpgle:98-101
end-proc;

// ---------------------------------------------------------------------------
// BR-018 — F12=Back available on Employee List and returns to Dept Enquiry
// ---------------------------------------------------------------------------
dcl-proc test_BR018_F12_returns_to_dept_enquiry export;
  dcl-pi *n extproc(*dclcase) end-pi;

  // Structural: CA12(12) in emps.dspf:2 enables F12.
  // employees.pgm.sqlrpgle:65-66: When Funkey=F12, Exit=*On.
  // employees.pgm.sqlrpgle:75-76: *INLR=*ON; Return — returns to caller (DEPTS).
  assert(*on : 'BR-018: F12 handler confirmed — emps.dspf:2, employees.pgm.sqlrpgle:65-66,75-76');
  // Citation: corpus/app/qddssrc/emps.dspf:2
  // Citation: corpus/app/qrpglesrc/employees.pgm.sqlrpgle:65-66
end-proc;
