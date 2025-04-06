let
  customFunction =
// 1.0: invokeFunction & define parameter inputs documentation
  
    let
    documentation = [
        // Inspired by Enterprise DNA - Melissa de Korte (https://www.youtube.com/watch?v=H8F60sgQZOI)
        Documentation.Name = " fnDates ", 
        Documentation.Description = " Dates Table with Fiscal and Academic Year ", 
        Documentation.LongDescription = "    
                <p><b>  Date Table Generator  </b></p>

                <li>------------------------------------------------------</li>
                
                <li><b>  Creator: </b> Imran Haq  </li>
                <li><b>  Web: </b> https://github.com/PBIQueryous/M-Code/tree/main/Calendars  </li>
                <li><b>  Special Thanks and Original Author: </b> Melissa de Korte  </li>
                <li><b>  LinkedIn: </b> (https://www.linkedin.com/in/melissa-de-korte/)  </li>
                <li><b>  Github: </b> (https://gist.github.com/m-dekorte)  </li>
                <li> Very special thanks to Melissa de Korte, Power Query Wizard. </li>
                <li>  This work would not be possible without Melissa's original Extended Date Table. 
                <li> Melissa is the true inspiration and deserves all the credit. </li>

                <li>------------------------------------------------------</li>

                <li><b>  Editor: </b>  Oscar Martinez  </li>
                <li><b>  Web: </b>  https://bibb.pro  </li>
                <li><b>  LinkedIn: </b>  https://www.linkedin.com/in/oscarmartinezv/  </li>

                <li>------------------------------------------------------</li>

                <p><b>  Function Description:  </b></p>
                <p>  This function generates a date table with a range of dates from the start year to the end year. Additional parameters are available generate Fiscal/Financial and Academic Year columns.  </p>
                <p><b>  Parameters:  </b></p>
                <ul>
                    <li><b>  Year Start :  </b>  The starting year of the date range. <code> (eg: 2023) </code> </li>
                    <li><b>  Year End:  </b>  The ending year of the date range. <code> (eg: 2025) </code> </li>
                    <li><b>  Fiscal Month Start (optional):  </b>  The fiscal year start month.  <code> (eg: 4) </code> </li>
                    <li><b>  Business Month Start (optional):  </b>  The business year start month.  <code> (eg: 8) </code> </li>
                    <li><b>  Holidays (optional):  </b>  Provide a list of public holidays.   </li>
                    <li><b>  Weekday Start Number (optional):  </b>  Weekday start (1 = Monday, 0 = Sunday).  <code> (eg: null) </code> </li>
                    <li><b>  Relative Net Workdays (optional):  </b>  Include Relative Net Work Days.  <code> (eg: null) </code> </li>
                </ul>
                <p><b>  Returns:  </b></p>
                <p>  A date table.  </p>

                <li><b>  fx:  </b> <code> = fnDates(2023, 2025, 4, 8, null, null, null) </code> </li>
            ", 
        Documentation.Category = " Dates / Calendar ", 
        Documentation.Source = "  PBI Queryous  ", 
        Documentation.Version = " 5.0: Upated for Oscar Valderock", 
        Documentation.Author = " Imran Haq ", 
        Documentation.Examples = {
          [
            Description = "  Dates Table with Fiscal and Academic Year   ", 
            Code = " = fnDates(2023, 2025, 4, 8, null, null, null) ", 
            Result = 
"
  1. Input paramaters
  2. Invoke function
  3. Optional: replace start / end year parameters with dynamic values to automatically extend table

"
          ]
        /* ,
            [
            Description = "  description   ",
            Code    = " code ", 
            Result  = " result #(cr,lf) new line
                      #(cr,lf) new line #(cr,lf) 2 "
            ] */
        }
      ], 
     // 4.0: edit function metadata here
fnDateTable = ( 
                p_year_start as number, 
                p_year_end as number, 
                optional p_fiscal_year_start_month_num as number,
                optional p_business_year_start_month_num as number, 
                optional p_holidays as list, 
                optional p_weekday_start_num as number, 
                optional p_add_relative_net_work_days as logical 
                ) 
                as table =>

// let  debug =
let
/* ///  -- DEBUG PARAMETERS
        p_year_start = null ?? 1999,
        p_year_end = null ?? 2000,
///  -- DEBUG PARAMETERS

        p_fiscal_year_start_month_num = null ?? 2,
        p_business_year_start_month_num = null ?? 3, 
        p_holidays = null, 
        p_weekday_start_num = 1, 
        p_add_relative_net_work_days = true, 
///  -- DEBUG PARAMETERS */
        // p_year_start = null ?? Date.Year(Date.From(DateTimeZone.FixedUtcNow()))-1,
        // p_year_end = null ?? p_year_start+1,
        p_start_date = #date(p_year_start,01,01), 
        p_end_date = #date(p_year_end,12,31), 
        p_fiscal_year_start_month_num = null ?? 4,
        p_business_year_start_month_num = null ?? 3, 
        p_holidays = null, 
        p_weekday_start_num = 1, 
        p_add_relative_net_work_days = true, 
       v_fy_start_month = List.Select({1..12}, each _ = p_fiscal_year_start_month_num){0}? ?? 1,
        v_by_start_month = List.Select({1..12}, each _ = p_business_year_start_month_num){0}? ?? 1,
        v_week_day_start = List.Select({0..1}, each _ = p_weekday_start_num){0}? ?? 0,
        v_current_date = Date.From(DateTimeZone.FixedUtcNow()),
        v_current_month_num = Date.Month(v_current_date),
        v_day_count = Duration.Days(Duration.From(p_end_date -  p_start_date)) + 1,
        v_week_start = Day.Monday,
        v_holidays_provided = p_holidays <> null,

        v_Source = List.Dates(p_start_date, v_day_count, Duration.From(1)),
        v_add_today = if List.Contains(v_Source, v_current_date) then v_Source else List.Combine({v_Source, {v_current_date}}),
        v_to_table = Table.FromColumns({v_add_today}, type table [date_id = date]),
    v_date_serial = Table.AddColumn(v_to_table, "date_serial_number", each Duration.Days([date_id] - #date(1900, 1, 1)), Int64.Type),

        /*  === Year Columns === */
        v_rec_years = Table.AddColumn(v_date_serial, "rec_year", each [
            calendar_year = Date.Year([date_id]),
            current_year = Date.Year(v_current_date),
            calendar_year_offset = calendar_year - current_year,
            is_year_complete = if Date.EndOfYear([date_id]) < Date.EndOfYear(v_current_date) then 1 else 0,
            is_cmtd = if ([date_id] <= Date.AddDays(Date.StartOfMonth(Date.From(v_current_date)), -1)) then 1 else 0,
            is_ytd = if ([date_id] <= Date.From(v_current_date)) then 1 else 0,
            is_frc = if ([date_id] > Date.From(v_current_date)) then 1 else 0
        ], type [calendar_year=Int64.Type, calendar_year_offset=Int64.Type, is_year_complete=Int64.Type, is_cmtd=Int64.Type, is_ytd=Int64.Type, is_frc=Int64.Type]),
        v_exp_rec_years = Table.ExpandRecordColumn(v_rec_years, "rec_year", {"calendar_year", "calendar_year_offset", "is_year_complete", "is_cmtd", "is_ytd", "is_frc"}),
    
    /*  === quarter Columns === */
        v_rec_quarters = Table.AddColumn(v_exp_rec_years, "QuarterRecord", each [
            quarter_num = Date.QuarterOfYear([date_id]),
            quarter = "Q" & Number.ToText(quarter_num),
            quarter_start = Date.StartOfQuarter([date_id]),
            quarter_end = Date.EndOfQuarter([date_id]),
            quarter_year = "Q" & Number.ToText(quarter_num) & Date.ToText([date_id], [Format = " yy"]),
            quarter_year_id = [calendar_year] * 100 + quarter_num,
            quarter_offset = ((4 * Date.Year([date_id])) + quarter_num) - ((4 * Date.Year(v_current_date)) + Date.QuarterOfYear(v_current_date)),
            is_quarter_completed = if quarter_end < Date.EndOfQuarter(v_current_date) then 1 else 0
        ], type [quarter_num=Int64.Type, quarter=text, quarter_start=date, quarter_end=date, quarter_year=text, quarter_year_id=Int64.Type, quarter_offset=Int64.Type, is_quarter_completed=Int64.Type]),
        v_exp_rec_quarters = Table.ExpandRecordColumn(v_rec_quarters, "QuarterRecord", 
            {"quarter_num", "quarter", "quarter_start", "quarter_end", "quarter_year", "quarter_year_id", "quarter_offset", "is_quarter_completed"}),

        /*  === Month Columns === */
        v_rec_months = Table.AddColumn(v_exp_rec_quarters, "MonthRecord", each [
            month_num = Date.Month([date_id]),
            month_start = Date.StartOfMonth([date_id]),
            month_end = Date.EndOfMonth([date_id]),
            month_year = Text.Proper(Date.ToText([date_id], [Format = "MMM-yy"])),
            month_year_id = [calendar_year] * 100 + month_num,
            month_offset = ((12 * Date.Year([date_id])) + month_num) - ((12 * Date.Year(v_current_date)) + Date.Month(v_current_date)),
            is_month_complete = if month_end < Date.EndOfMonth(v_current_date) then 1 else 0,
            month_name = Text.Proper(Date.ToText([date_id], "MMMM")),
            month_name_short = Text.Proper(Date.ToText([date_id], "MMM")),
            month_initial = Text.Start(Text.Proper(Date.ToText([date_id], "MMMM")), 1) & Text.Repeat(Character.FromNumber(8203), month_num),
            month_day = Date.Day([date_id]),
            month_selection = if month_num = v_current_month_num then "Current Month" else month_name_short
        ], type [month_num=Int64.Type, month_start=date, month_end=date, month_year=text, month_year_id=Int64.Type, month_offset=Int64.Type, is_month_complete=Int64.Type, month_name=text, month_name_short=text, month_selection=text, month_initial=text, month_day=Int64.Type]),
        v_exp_rec_months = Table.ExpandRecordColumn(v_rec_months, "MonthRecord", 
            {"month_num", "month_start", "month_end", "month_year", "month_year_id", "month_offset", "is_month_complete", "month_name", "month_name_short", "month_selection", "month_initial", "month_day"}),

        /*  === Week Columns === */
        v_rec_weeks = Table.AddColumn(v_exp_rec_months, "WeekRecord", each [
            week_number_calc = Number.RoundDown((Date.DayOfYear([date_id]) - (Date.DayOfWeek([date_id], v_week_start) + 1) + 10) / 7),
            week_num = if week_number_calc = 0 
                then Number.RoundDown((Date.DayOfYear(#date(Date.Year([date_id]) - 1, 12, 31)) - (Date.DayOfWeek(#date(Date.Year([date_id]) - 1, 12, 31), v_week_start) + 1) + 10) / 7)
                else if (week_number_calc = 53 and (Date.DayOfWeek(#date(Date.Year([date_id]), 12, 31), v_week_start) + 1 < 4)) then 1 else week_number_calc,
            week_start = Date.StartOfWeek([date_id], v_week_start),
            week_end = Date.EndOfWeek([date_id], v_week_start),
            week_year = "W" & Text.PadStart(Text.From(week_num), 2, "0") & " " & Text.End(Text.From(Date.Year(Date.AddDays(week_start, 3))),2),
            week_year_id = Date.Year(Date.AddDays(week_start, 3)) * 100 + week_num,
            week_offset = (Number.From(week_start) - Number.From(Date.StartOfWeek(v_current_date, v_week_start))) / 7,
            is_week_complete = if week_end < Date.EndOfWeek(v_current_date, v_week_start) then 1 else 0
        ], type [week_num=Int64.Type, week_start=date, week_end=date, week_year=text, week_year_id=Int64.Type, week_offset=Int64.Type, is_week_complete=Int64.Type]),
        v_exp_rec_weeks = Table.ExpandRecordColumn(v_rec_weeks, "WeekRecord", 
            {"week_num", "week_start", "week_end", "week_year", "week_year_id", "week_offset", "is_week_complete"}),

        /* === Day Columns === */
        v_rec_days = Table.AddColumn(v_exp_rec_weeks, "DayRecord", each [
            week_day_num = Date.DayOfWeek([date_id], v_week_start) + v_week_day_start,
            week_day_name = Text.Proper(Date.ToText([date_id], "dddd")),
            week_day_initial = Text.Proper(Text.Start(week_day_name, 1)) & Text.Repeat(Character.FromNumber(8203), Date.DayOfWeek([date_id], v_week_start) + v_week_day_start),
            day_year = Date.DayOfYear([date_id]),
            day_id = [calendar_year] * 10000 + [month_num] * 100 + [month_day],
            day_offset = Number.From([date_id]) - Number.From(v_current_date),
            is_future = if not ([date_id] <= v_current_date) then 1 else 0,
            is_week_day = if Date.DayOfWeek([date_id], v_week_start) > 4 then 0 else 1,
            is_holiday = if not v_holidays_provided then "Unknown" else List.Contains(p_holidays, [date_id]),
            is_work_day = if (if Date.DayOfWeek([date_id], v_week_start) > 4 then false else true) and (if v_holidays_provided then not List.Contains(p_holidays, [date_id]) else true) then 1 else 0,
            date_type = if v_holidays_provided and List.Contains(p_holidays, [date_id]) then "Holiday" 
                else if (if Date.DayOfWeek([date_id], v_week_start) > 4 then false else true) = false then "Weekend" 
                else if (if Date.DayOfWeek([date_id], v_week_start) > 4 then false else true) = true then "Weekday" else null
        ], type [week_day_num=Int64.Type, week_day_name=text, week_day_initial=text, day_year=Int64.Type, day_id=Int64.Type, day_offset=Int64.Type, is_future=number, is_week_day=number, is_holiday= (if v_holidays_provided then Logical.Type else Text.Type), is_work_day=number, date_type=text]),
        v_exp_rec_days = Table.ExpandRecordColumn(v_rec_days, "DayRecord", 
            {"week_day_num", "week_day_name", "week_day_initial", "day_year", "day_id", "day_offset", "is_future", "is_week_day", "is_holiday", "is_work_day", "date_type"}),

        /* === ISO Columns === */
        v_rec_iso_fields = Table.AddColumn(v_exp_rec_days, "ISORecords", each [
iso_year = Date.Year(Date.AddDays(Date.StartOfWeek([date_id], v_week_start), 3)),
iso_quarter_num = if [week_num] > 39 then 4 else if [week_num] > 26 then 3 else if [week_num] > 13 then 2 else 1,
iso_quarter = "Q" & Number.ToText(iso_quarter_num),
iso_quarter_year = "Q" & Number.ToText(iso_quarter_num) & " " & Text.End(Number.ToText(iso_year),2),
iso_quarter_year_id = iso_year * 100 + iso_quarter_num
], type [iso_year=number, iso_quarter_num=number, iso_quarter=text, iso_quarter_year=text, iso_quarter_year_id=number]
),
    v_exp_rec_iso_fields = Table.ExpandRecordColumn(v_rec_iso_fields, "ISORecords", {"iso_year", "iso_quarter_num", "iso_quarter", "iso_quarter_year", "iso_quarter_year_id"}),
       
        /* === Business Columns START === */
        v_rec_business_fields = Table.AddColumn(
            v_exp_rec_iso_fields, 
            "BusinessRecords", 
            each [
            business_year_num = (if [month_num] >= v_by_start_month and v_by_start_month > 1 then [calendar_year] + 1 else [calendar_year]), 
            business_year_offset = (if [month_num] >= v_by_start_month then ([calendar_year] + 1) else [calendar_year])
                - (if v_current_month_num >= v_by_start_month then (Date.Year(v_current_date) + 1) else Date.Year(v_current_date)),
            business_year = Text.End(Text.From(business_year_num -1), 2) & "/" & Text.End(Text.From(business_year_num ), 2), 
            business_year_selection = if business_year_offset = 0 then "Current Business Year" else business_year,
            is_current_by = if business_year_offset = 0 then 1 else 0,
            is_previous_by = if business_year_offset = -1 then 1 else 0,
            business_year_short = "BY" & Text.End(Text.From(business_year_num), 2), 
            business_year_quarter = "BQ" & Text.From(Number.RoundUp(Date.Month(Date.AddMonths([date_id], - (v_by_start_month - 1))) / 3)) & " " & Text.End(Text.From(business_year_num), 2), 
            business_year_quarter_number = business_year_num * 100 + Number.RoundUp(Date.Month(Date.AddMonths([date_id], - (v_by_start_month - 1))) / 3), 
            business_period_num = 
                if [month_num] >= v_by_start_month and v_by_start_month > 1 
                then  [month_num] - (v_by_start_month - 1)
                else if [month_num] >= v_by_start_month and v_by_start_month = 1 
                then  [month_num]
                else  [month_num] + (12 - v_by_start_month + 1), 
            business_period = "BY" & Text.End(Text.From(business_year_num), 2) & " " & "P" & Text.PadStart(Text.From(business_period_num), 2, "0"), 
            business_month_name_short = [month_name_short],
            business_month_year_id = (business_year_num * 100 + business_period_num), 
            business_month_year = [month_year],
            business_year_first_day = #date(Date.Year(p_start_date) - 1, v_by_start_month, 1), 
            business_year_start = if [month_num] >= v_by_start_month then #date([calendar_year], v_by_start_month, 1) else #date([calendar_year] - 1, v_by_start_month, 1)  ,    
            business_year_end = if [month_num] >= v_by_start_month then Date.AddDays(#date([calendar_year]+1, v_by_start_month, 1),-1) else Date.AddDays(#date([calendar_year] - 0, v_by_start_month, 1),-1),
            business_week_start = Date.StartOfWeek(business_year_first_day, v_week_start),
            current_week_start = Date.StartOfWeek([date_id], v_week_start),
            week_diff = (Duration.Days(current_week_start - business_week_start) / 7),
            business_week_num = Number.RoundDown(week_diff) + 1,
            business_week = "BW" & Text.PadStart( Text.From(business_week_num), 2, "0") & " " & Text.End(Text.From(business_year_num),2)
            ], 
            type [
            business_year_num = number, 
            business_year_offset = Int64.Type, 
            business_year = text, 
            business_year_selection = text,
            is_current_by = Int64.Type,
            is_previous_by = Int64.Type,
            business_year_quarter = text, 
            business_year_quarter_number = number, 
            business_period_num = number,
            business_month_name_short = text,
            business_period = text, 
            business_month_year_id = number,
            business_month_year = text, 
            //business_year_first_day = date,
            business_year_start = date,
            business_year_end = date ,
            business_week_num = number,
            business_week = text
            ]
        ), 
        v_exp_rec_business_fields = Table.ExpandRecordColumn(
            v_rec_business_fields, 
            "BusinessRecords", 
            {
            "business_year_num", 
            "business_year_offset", 
            "business_year", 
            "business_year_selection",
            "is_current_by",
            "is_previous_by",
            "business_year_quarter", 
            "business_year_quarter_number", 
            "business_period_num", 
            "business_month_name_short",
            "business_period", 
            "business_month_year_id",
            "business_month_year",
            //"business_year_first_day",
            "business_year_start", 
            "business_year_end",
            "business_week_num",
            "business_week"
            }
        ),
        /* === Business Columns END === */

        /* === Fiscal Columns START === */
        v_rec_fiscal_fields = Table.AddColumn(
            v_exp_rec_business_fields, 
            "BusinessRecords", 
            each [
            fiscal_year_num = (if [month_num] >= v_fy_start_month and v_fy_start_month > 1 then [calendar_year] + 1 else [calendar_year]), 
            fiscal_year_offset = (if [month_num] >= v_fy_start_month then ([calendar_year] + 1) else [calendar_year])
                - (if v_current_month_num >= v_fy_start_month then (Date.Year(v_current_date) + 1) else Date.Year(v_current_date)),
            fiscal_year = Text.End(Text.From(fiscal_year_num -1), 2) & "/" & Text.End(Text.From(fiscal_year_num ), 2), 
            fiscal_year_selection = if fiscal_year_offset = 0 then "Current Fiscal Year" else fiscal_year,
            is_current_fy = if fiscal_year_offset = 0 then 1 else 0,
            is_previous_fy = if fiscal_year_offset = -1 then 1 else 0,
            fiscal_year_short = "FY" & Text.End(Text.From(fiscal_year_num), 2), 
            fiscal_year_quarter = "FQ" & Text.From(Number.RoundUp(Date.Month(Date.AddMonths([date_id], - (v_fy_start_month - 1))) / 3)) & " " & Text.End(Text.From(fiscal_year_num), 2), 
            fiscal_year_quarter_number = fiscal_year_num * 100 + Number.RoundUp(Date.Month(Date.AddMonths([date_id], - (v_fy_start_month - 1))) / 3), 
            fiscal_period_num = 
                if [month_num] >= v_fy_start_month and v_fy_start_month > 1 
                then  [month_num] - (v_fy_start_month - 1)
                else if [month_num] >= v_fy_start_month and v_fy_start_month = 1 
                then  [month_num]
                else  [month_num] + (12 - v_fy_start_month + 1), 
            fiscal_period = "FY" & Text.End(Text.From(fiscal_year_num), 2) & " " & "P" & Text.PadStart(Text.From(fiscal_period_num), 2, "0"), 
            fiscal_month_name_short = [month_name_short],
            fiscal_month_year_id = (fiscal_year_num * 100 + fiscal_period_num), 
            fiscal_month_year = [month_year],
            fiscal_year_first_day = #date(Date.Year(p_start_date) - 1, v_fy_start_month, 1), 
            fiscal_year_start = if [month_num] >= v_fy_start_month then #date([calendar_year], v_fy_start_month, 1) else #date([calendar_year] - 1, v_fy_start_month, 1),
            fiscal_year_end = if [month_num] >= v_fy_start_month then Date.AddDays(#date([calendar_year] +1, v_fy_start_month, 1), -1) else Date.AddDays(#date([calendar_year] + 0, v_fy_start_month, 1),-1),
            fiscal_week_start = Date.StartOfWeek(fiscal_year_first_day, v_week_start),
            current_week_start = Date.StartOfWeek([date_id], v_week_start),
            week_diff = (Duration.Days(current_week_start - fiscal_week_start) / 7),
            fiscal_week_num = Number.RoundDown(week_diff) + 1,
            fiscal_week = "BW" & Text.PadStart( Text.From(fiscal_week_num), 2, "0") & " " & Text.End(Text.From(fiscal_year_num),2)
            ], 
            type [
            fiscal_year_num = number, 
            fiscal_year_offset = Int64.Type, 
            fiscal_year = text, 
            fiscal_year_selection = text,
            is_current_fy = Int64.Type,
            is_previous_fy = Int64.Type,
            fiscal_year_quarter = text, 
            fiscal_year_quarter_number = number, 
            fiscal_period_num = number, 
            fiscal_month_name_short = text,
            fiscal_period = text, 
            fiscal_month_year_id = number, 
            fiscal_month_year = text,
            //fiscal_year_first_day = date,
            fiscal_year_start = date,
            fiscal_year_end = date ,
            fiscal_week_num = number,
            fiscal_week = text
            ]
        ), 
        v_exp_rec_fiscal_fields = Table.ExpandRecordColumn(
            v_rec_fiscal_fields, 
            "BusinessRecords", 
            {
            "fiscal_year_num", 
            "fiscal_year_offset", 
            "fiscal_year", 
            "fiscal_year_selection",
            "is_current_fy",
            "is_previous_fy",
            "fiscal_year_quarter", 
            "fiscal_year_quarter_number", 
            "fiscal_period_num", 
            "fiscal_month_name_short",
            "fiscal_period", 
            "fiscal_month_year_id", 
            "fiscal_month_year",
            //"fiscal_year_first_day",
            "fiscal_year_start",
            "fiscal_year_end" ,
            "fiscal_week_num",
            "fiscal_week"
            }
        ),
        /* === Fiscal Columns END === */

        v_col_fiscal_quarter = Table.AddColumn(v_exp_rec_fiscal_fields, "fiscal_quarter", each "FQ" & Text.From( Number.RoundUp( Date.Month( Date.AddMonths( [date_id], - (v_fy_start_month -1) )) / 3 )) & " " & Text.End(Text.From([fiscal_year_num]),2), type text),
        v_col_fiscal_quarter_num = Table.AddColumn(v_col_fiscal_quarter, "fiscal_quarter_year_id", each [fiscal_year_num] * 10 + Number.RoundUp( Date.Month( Date.AddMonths( [date_id], - (v_fy_start_month -1) )) / 3 ), type number),
        v_col_fiscal_month_num = Table.AddColumn(v_col_fiscal_quarter_num, "fiscal_period_number", each if [month_num] >= v_fy_start_month and v_fy_start_month >1 then [month_num] - (v_fy_start_month-1) else if [month_num] >= v_fy_start_month and v_fy_start_month =1 then [month_num] else [month_num] + (12-v_fy_start_month+1), type number),
        v_col_fiscal_period = Table.AddColumn(v_col_fiscal_month_num, "fiscal_period_year", each "FP" & Text.PadStart( Text.From([fiscal_period_number]), 2, "0") & " " & Text.From([fiscal_year_num]), type text),
        v_col_fiscal_month_year_id = Table.AddColumn(v_col_fiscal_period , "fiscal_period_year_id", each [fiscal_year_num] * 100 + [fiscal_period_number], type number),
        v_col_fiscal_year_start = #date( Date.Year(p_start_date)-1, v_fy_start_month, 1 ),
        v_col_fiscal_year_first_day = Table.AddColumn(v_col_fiscal_month_year_id, "fiscal_first_day", each if [month_num] >= v_fy_start_month then #date([calendar_year], v_fy_start_month, 1) else #date([calendar_year]-1, v_fy_start_month, 1), type date),
        v_fiscal_week_logic = List.Contains( {null}, p_fiscal_year_start_month_num),
        v_fiscal_week_logic_updated = if v_fiscal_week_logic then Table.ReplaceValue(v_col_fiscal_year_first_day, each [fiscal_week_num], each if v_fy_start_month =1 then [week_num] else [fiscal_week_num], Replacer.ReplaceValue, {"fiscal_week_num"}) else v_col_fiscal_year_first_day,
        v_col_fiscal_week = Table.AddColumn( v_fiscal_week_logic_updated, "fiscal_week_label", each if v_fiscal_week_logic then "F" & [week_year] else "FW" & Text.PadStart( Text.From([fiscal_week_num]), 2, "0") & " " & Text.End(Text.From([fiscal_year_num]),2), type text),
        v_col_fiscal_week_year_id = Table.AddColumn(v_col_fiscal_week, "fiscal_week_year_id", each if v_fiscal_week_logic then [week_year_id] else [fiscal_year_num] * 100 + [fiscal_week_num],  Int64.Type),

        /*  === Get Current Date Values === */
        v_current_date_record = Table.SelectRows(v_col_fiscal_week_year_id, each ([date_id] = v_current_date)),
        v_current_iso_year = v_current_date_record{0}[iso_year],
        v_current_iso_quarter_num = v_current_date_record{0}[iso_quarter_num],
        v_current_year = v_current_date_record{0}[calendar_year],
        v_current_month = v_current_date_record{0}[month_num],
        v_current_fiscal_first_day = v_current_date_record{0}[fiscal_first_day],
        v_previous_fiscal_first_day = Date.AddYears(v_current_fiscal_first_day, -1),
        v_current_fy = v_current_date_record{0}[fiscal_year],
        v_current_fq = v_current_date_record{0}[fiscal_quarter_year_id],
        v_current_fiscal_period_id = v_current_date_record{0}[fiscal_period_year_id],
        v_current_fw = v_current_date_record{0}[fiscal_week_year_id],

        /*  === Others & Clean up === */
        v_col_iso_year_offset = Table.AddColumn(v_col_fiscal_week_year_id, "iso_calendar_year_offset", each [iso_year] - v_current_iso_year, Int64.Type),
        v_col_iso_quarter_offset = Table.AddColumn(v_col_iso_year_offset, "iso_quarter_offset", each ((4 * [iso_year]) + [iso_quarter_num]) - ((4 * v_current_iso_year) + v_current_iso_quarter_num), Int64.Type),
        v_col_is_current_fq = Table.RemoveColumns( Table.AddColumn(v_col_iso_quarter_offset, "is_current_fq", each if [fiscal_quarter_year_id] = v_current_fq then true else false, type logical), {"fiscal_year_num"} ),
        v_col_is_current_fp = Table.AddColumn(v_col_is_current_fq, "is_current_fp", each if [fiscal_period_year_id] = v_current_fiscal_period_id then true else false, type logical),
        v_col_is_current_fw = Table.AddColumn(v_col_is_current_fp, "is_current_fw", each if [fiscal_week_year_id] = v_current_fw then true else false, type logical),
        v_col_is_pytd = Table.AddColumn(v_col_is_current_fw, "is_pytd", each if v_current_year-1 = [calendar_year] and [day_year] <= v_current_date_record{0}[day_year] then true else false, type logical),
        v_col_is_pftyd = Table.AddColumn(v_col_is_pytd, "is_pfytd", each if [fiscal_year_offset] = -1 then Duration.Days([date_id] - v_previous_fiscal_first_day) + 1 <= Duration.Days(v_current_date - v_current_fiscal_first_day) + 1 else false, type logical),
        v_col_net_workdays = if p_add_relative_net_work_days = true then Table.AddColumn(v_col_is_pftyd, "relative_net_workdays", each fxNETWORKDAYS( p_start_date, [date_id], p_holidays ), Int64.Type) else v_col_is_pftyd,
        fxNETWORKDAYS = (p_start_date, p_end_date, optional holidays as list) =>
        let
            ListOfDates = List.Dates( p_start_date, Number.From(p_end_date-p_start_date)+1, Duration.From(1) ),
            DeleteHolidays = if holidays = null then ListOfDates else List.Difference( ListOfDates, List.Transform(holidays, Date.From )),
            DeleteWeekends = List.Select( DeleteHolidays, each Date.DayOfWeek( _, v_week_start) < 5 ),
            CountDays = List.Count( DeleteWeekends)
        in
            CountDays,
        v_remove_today = Table.RemoveColumns(if not List.Contains(v_Source, v_current_date) then Table.SelectRows(v_col_net_workdays, each ([date_id] <> v_current_date)) else v_col_net_workdays, {"day_year", "fiscal_first_day"}),
        v_format_types = Table.TransformColumnTypes(v_remove_today, {{"calendar_year", Int64.Type}, {"quarter_num", Int64.Type}, {"month_num", Int64.Type}, {"month_day", Int64.Type}, {"day_id", Int64.Type}, {"week_day_num", Int64.Type}, {"iso_calendar_year_offset", Int64.Type}, {"iso_quarter_year_id", Int64.Type}, {"iso_quarter_offset", Int64.Type}, {"week_num", Int64.Type}, {"week_year_id", Int64.Type}, {"month_year_id", Int64.Type}, {"quarter_year_id", Int64.Type}, {"fiscal_quarter_year_id", Int64.Type}, {"fiscal_period_number", Int64.Type}, {"fiscal_period_year_id", Int64.Type}, {"week_offset", Int64.Type}, {"month_offset", Int64.Type}, {"quarter_offset", Int64.Type}, {"calendar_year_offset", Int64.Type}, {"fiscal_year_offset", Int64.Type}, {"fiscal_week_num", Int64.Type}}),
        v_reorder_cols = Table.ReorderColumns(v_format_types,{"date_id", "date_serial_number", "calendar_year", "calendar_year_offset", "is_year_complete", "is_cmtd", "is_ytd", "is_frc", "quarter_num", "quarter", "quarter_start", "quarter_end", "quarter_year", "quarter_year_id", "quarter_offset", "is_quarter_completed", "month_num", "month_start", "month_end", "month_year", "month_year_id", "month_offset", "is_month_complete", "month_name", "month_name_short", "month_selection", "month_initial", "month_day", "week_num", "week_start", "week_end", "week_year", "week_year_id", "week_offset", "is_week_complete", "week_day_num", "week_day_name", "week_day_initial", "day_id", "day_offset", "is_future", "is_week_day", "is_holiday", "is_work_day", "date_type", "iso_year", "iso_calendar_year_offset", "iso_quarter_num", "iso_quarter", "iso_quarter_year", "iso_quarter_year_id", "iso_quarter_offset", "business_year_num", "business_year_offset", "business_year", "business_year_selection", "is_current_by", "is_previous_by", "business_year_quarter", "business_year_quarter_number", "business_period_num", "business_period", "business_month_year_id", "business_year_start", "business_year_end", "business_week_num", "business_week", "fiscal_year_selection", "fiscal_year", "is_previous_fy", "fiscal_year_quarter", "fiscal_year_quarter_number", "fiscal_period_num", "fiscal_period", "fiscal_month_year_id", "fiscal_year_start", "fiscal_year_end", "fiscal_year_offset", "fiscal_quarter", "fiscal_quarter_year_id", "fiscal_period_number", "fiscal_period_year", "fiscal_period_year_id", "fiscal_week_num", "fiscal_week_label", "fiscal_week", "fiscal_week_year_id", "is_current_fy", "is_current_fq", "is_current_fp", "is_current_fw", "is_pytd", "is_pfytd", "relative_net_workdays"}),
        v_list_cols = if v_fiscal_week_logic then Table.RemoveColumns(v_reorder_cols, {"iso_quarter_num", "fiscal_year", "fiscal_quarter", "fiscal_quarter_year_id", "fiscal_period_number", "fiscal_period_year", "fiscal_period_year_id", "fiscal_week_num", "fiscal_week", "fiscal_week_year_id", "fiscal_year_offset", "is_current_fy", "is_current_fq", "is_current_fp", "is_current_fw", "is_pfytd"}) else Table.RemoveColumns(v_reorder_cols, {"fiscal_period_number", "fiscal_week_num", "iso_quarter_num"})
    in
        v_list_cols

//in debug
        , 
      // ------------------------------------------------------------------     
      /*
  fnDateTable = (
    StartYearNUM as number, 
    EndYearNUM as number, 
    optional FYStartMonthNum as number, 
    optional AYStartMonthNum as number, 
    optional Holidays as list, 
    optional WDStartNum as number, 
    optional AddRelativeNetWorkdays as logical
  ) as table =>
*/
      // 3.0: change parameter metadata here
      fnType = type function (
        // 3.0.1: Calendar Start Year parameter
        p_year_start as (
          type number
            meta [
              Documentation.FieldCaption     = " Calendar Year Start", 
              Documentation.FieldDescription = " Format: YYYY #(lf) eg: #(lf) 2025 ", 
              Documentation.SampleValues     = {2025}
            ]
        ), 
        // 3.0.2: Calendar End Year parameter
        p_year_end as (
          type number
            meta [
              Documentation.FieldCaption     = " Calendar Year End", 
              Documentation.FieldDescription = " Format: YYYY #(lf) eg: #(lf) 2025 ", 
              Documentation.SampleValues     = {2023}
            ]
        ), 
        // 3.0.3: Fiscal Start Month parameter
        optional p_fiscal_year_start_month_num as (
          type number
            meta [
              Documentation.FieldCaption     = " Fiscal Month Start", 
              Documentation.FieldDescription = " Format: MM #(lf) eg: #(lf) Feb = 2 #(lf) Mar = 3 ", 
              Documentation.SampleValues     = {02}
            ]
        )// 3.0.4: Academic Start Month parameter
        , 
        optional p_business_year_start_month_num as (
          type number
            meta [
              Documentation.FieldCaption     = " Business Month Start ", 
              Documentation.FieldDescription = " Format: MM #(lf) eg: #(lf) Feb = 2 #(lf) Mar = 3 ", 
              Documentation.SampleValues     = {08}
            ]
        )// 3.0.5: Holidays list parameter
        , 
        optional p_holidays as (
          type list
            meta [
              Documentation.FieldCaption     = " Choose holidays as a list ", 
              Documentation.FieldDescription = " Choose holidays as a list ", 
              Documentation.SampleValues     = {"List"}
            ]
        )// 3.0.6: Weekday Start parameter 
        , 
        optional p_weekday_start_num as (
          type number
            meta [
              Documentation.FieldCaption     = " Input weekday start number  ", 
              Documentation.FieldDescription = " (#) eg: #(lf) Monday = 1 ", 
              Documentation.SampleValues     = {01}
            ]
        )// 3.0.7: AddRelativeNetWorkdays parameter 
        , 
        optional p_add_relative_net_work_days as (
          type logical
            meta [
              Documentation.FieldCaption     = " Input relative network days as boolean ", 
              Documentation.FieldDescription = " Fromat: Boolean #(lf) eg: #(lf) True", 
              Documentation.SampleValues     = {"True/False"}
            ]
        )
      // 3.1: parameter return type   
      ) as list, 
      // ------------------------------------------------------------------
     
      // ------------------------------------------------------------------
      // 5.0: Choose between Parameter Documentation or Function Documentation
      functionDocumentation =  // -- function metadata                       
      Value.ReplaceType(
        fnDateTable, 
        Value.ReplaceMetadata(Value.Type(fnDateTable), documentation)
      ), 
      parameterDocumentation =  // -- parameter metadata                        
      Value.ReplaceType(functionDocumentation, fnType)
    in
      // ------------------------------------------------------------------
      // select one of the above steps and paste below
      functionDocumentation /* <-- Choose final documentation type */                                         
in
  customFunction
