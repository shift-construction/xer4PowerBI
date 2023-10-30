// XER4PowerBI
// GPL3.0 License
// Created by Shift @ shift-construction.com
// Github: https://github.com/shift-construction/xer4PowerBI

let
    Source = (#"XER File" as any) => let
      // Initial Import
      sourceTable = Table.FromColumns({Lines.FromBinary(#"XER File", null, null, 1252)}), 
  // Identify and assign table names to rows
  tableNamesAdded = Table.AddColumn(
    sourceTable, 
    "Table Name", 
    each if Text.StartsWith([Column1], "%T") then Text.RemoveRange([Column1], 0, 3) else null
  ), 
  tableNamesFilled = Table.FillDown(tableNamesAdded, {"Table Name"}), 
  // Filter out rows with table name markers and rows without table names
  rowsFiltered = Table.SelectRows(tableNamesFilled, each not Text.StartsWith([Column1], "%T")), 
  validRows = Table.SelectRows(rowsFiltered, each ([Table Name] <> null)), 
  // Remove the first three characters from all rows (to clean up the data)
  firstCharactersRemoved = Table.TransformColumns(
    validRows, 
    {{"Column1", each Text.RemoveRange(_, 0, 3), type text}}
  ), 
  // Group the rows by table name
  rowsGrouped = Table.Group(
    firstCharactersRemoved, 
    {"Table Name"}, 
    {{"Table Data", each _, type table [Column1 = nullable text, Table Name = nullable text]}}
  ), 
  // Create a lookup table for pretty names
  lookupTable = #table(
    {"Table Name", "Pretty Name"}, 
    {
      {"ACCOUNT", "Cost Accounts"}, 
      {"ACTVCODE", "Activity Code Values"}, 
      {"ACTVTYPE", "Activity Codes"}, 
      {"APPLYACTOPTIONS", "Apply Actual Options"}, 
      {"ASGNMNTACAT", "Assignment Code Assignments"}, 
      {"ASGNMNTCATTYPE", "Assignment Codes"}, 
      {"ASGNMNTCATVAL", "Assignment Code Values"}, 
      {"BUDGCHNG", "Budget Changes"}, 
      {"CALENDAR", "Calendars"}, 
      {"COSTTYPE", "Expense Categories"}, 
      {"CURRTYPE", "Currency Types"}, 
      {"DOCCATG", "Document Categories"}, 
      {"DOCSTAT", "Document Statuses"}, 
      {"DOCUMENT", "Work Products and Documents"}, 
      {"FINDATES", "Financial Periods"}, 
      {"FUNDSRC", "Funding Sources"}, 
      {"ISSUHIST", "Notification History"}, 
      {"MEMOTYPE", "Notebook Topics"}, 
      {"OBS", "OBS"}, 
      {"PCATTYPE", "Project Codes"}, 
      {"PCATVAL", "Project Code Values"}, 
      {"PHASE", "Phase"}, 
      {"PROJCOST", "Project Expenses"}, 
      {"PROJECT", "Projects"}, 
      {"PROJEST", "Estimate History"}, 
      {"PROJFUND", "Project Funding Assignments"}, 
      {"PROJISSU", "Issues"}, 
      {"PROJPCAT", "Project Code Assignments"}, 
      {"PROJTHRS", "Thresholds"}, 
      {"PROJWBS", "WBS"}, 
      {"PRORISK", "Risks"}, 
      {"RCATTYPE", "Resource Codes"}, 
      {"RCATVAL", "Resource Code Values"}, 
      {"RISKTYPE", "Risk Types"}, 
      {"ROLECATTYPE", "Role Codes"}, 
      {"ROLECATVAL", "Role Code Values"}, 
      {"ROLELIMIT", "Role Limits"}, 
      {"ROLERATE", "Role Prices"}, 
      {"ROLERCAT", "Role Code Assignments"}, 
      {"ROLES", "Roles"}, 
      {"RSRC", "Resources"}, 
      {"RSRCCURV", "Resource Curves"}, 
      {"RSRCCURVDATA", "Resource Curve Data"}, 
      {"RSRCLEVELLIST", "Resource Level List"}, 
      {"RSRCRATE", "Resource Prices"}, 
      {"RSRCRCAT", "Resource Code Assignments"}, 
      {"RSRCROLE", "Resource Role Assignments"}, 
      {"SCHEDOPTIONS", "Schedule Options"}, 
      {"SHIFT", "Shift Names"}, 
      {"SHIFTPER", "Shifts"}, 
      {"TASK", "Activities"}, 
      {"TASKACTV", "Activity Code Assignments"}, 
      {"TASKDOC", "Document Assignments"}, 
      {"TASKFDBK", "Activity Feedback"}, 
      {"TASKFIN", "Activity Past Period Actuals"}, 
      {"TASKMEMO", "Activity Notebook"}, 
      {"TASKNOTE", "Activity Notes to Resources"}, 
      {"TASKPRED", "Activity Relationships"}, 
      {"TASKPROC", "Activity Steps"}, 
      {"TASKRSRC", "Activity Resource Assignments"}, 
      {"TASKUSER", "Activity Owners"}, 
      {"THRSPARM", "Threshold Parameters"}, 
      {"TRSRCFIN", "Activity Resource Assignment Past Period Actuals"}, 
      {"UDFTYPE", "User Defined Fields"}, 
      {"UDFVALUE", "User Defined Field Values"}, 
      {"UMEASURE", "Units of Measure"}, 
      {"WBSBUDG", "Spending and Benefit Plans"}, 
      {"WBSMEMO", "EPS, Project and WBS Notebook"}, 
      {"WBSRSRC_QTY", "WBSRSRC QTY"}, 
      {"WBSSTEP", "WBS Milestones"}, 
      {"POBS", "Performing Organizational Breakdown Structure"}
    }
  ), 
  // Merge the lookup table to get the pretty names
  mergedTables = Table.NestedJoin(
    rowsGrouped, 
    {"Table Name"}, 
    lookupTable, 
    {"Table Name"}, 
    "Match", 
    JoinKind.LeftOuter
  ), 
  prettyNamesAdded = Table.ExpandTableColumn(
    mergedTables, 
    "Match", 
    {"Pretty Name"}, 
    {"Pretty Name"}
  ), 
  // Extract data into columns and promote headers
  splitDataByDelimiter = Table.TransformColumns(
    prettyNamesAdded, 
    {
      {
        "Table Data", 
        each Table.SplitColumn(
          Table.RemoveColumns(_, {"Table Name"}), 
          "Column1", 
          Splitter.SplitTextByDelimiter("#(tab)", QuoteStyle.Csv)
        )
      }
    }
  ), 
  promoteDataHeaders = Table.TransformColumns(
    splitDataByDelimiter, 
    {{"Table Data", each Table.PromoteHeaders(_, [PromoteAllScalars = true])}}
  )
in
  promoteDataHeaders

in
    Source
