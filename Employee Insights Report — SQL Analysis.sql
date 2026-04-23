-- "Employee Insights Report — SQL Analysis"--
-- ---------------------Question 1 — Salary Growth by Department------------------------------------------------
-- which departments have seen the highest average salary growth from their earliest records to their latest?---
-- Logic: Compare earliest vs latest avg salary per dept---------------------------------------------------------    
    WITH avg_YEAR_SALARY AS
    (SELECT 
	DE.dept_no ,
    ROUND(AVG(S.salary),2) avg_salary ,
    YEAR(S.from_date) salary_year
FROM salaries S
JOIN dept_emp DE
	ON s.emp_no = de.emp_no
    GROUP BY DE.dept_no,YEAR(S.from_date)
    ORDER BY DE.dept_no,YEAR(S.from_date))
   , dep_rang as
   ( SELECT 
		dept_no,
        MAX(salary_year) LATEST_YEAR,
        MIN(salary_year) EARLIEST_YEAR
	FROM avg_YEAR_SALARY
    GROUP BY dept_no ),
    avg_salary as 
    (select 
		ay.dept_no,
        dr.LATEST_YEAR,
        dr.EARLIEST_YEAR,
        max(case when ay.salary_year = dr.EARLIEST_YEAR then ay.avg_salary end)earliest_avg_salary,
        max(case when ay.salary_year = dr.LATEST_YEAR then ay.avg_salary end) latest_avg_salary
	from avg_YEAR_SALARY ay
    join dep_rang dr
		on ay.dept_no = dr.dept_no
    group by ay.dept_no, dr.LATEST_YEAR, dr.EARLIEST_YEAR)
    select 
		avg_s.dept_no,
        avg_s.earliest_avg_salary,
        avg_s.latest_avg_salary,
        (avg_s.latest_avg_salary - avg_s.earliest_avg_salary ) salary_growth,
        rank()over(order by(avg_s.latest_avg_salary - avg_s.earliest_avg_salary ) DESC) growth_rank 
    from avg_salary avg_s
    join departments d
		on avg_s.dept_no = d.dept_no
        ORDER BY growth_rank ASC;
-- -------------------------Question 2 — Top 3 Earners Per Department------------------------------------
-- Who are the current top 3 highest paid employees in each department? ---------------------------------
-- Show their name, department, and salary.--------------------------------------------------------------
with current_salary as (
select 
	s.emp_no ,
    s.salary ,
    de.dept_no 
from salaries s
join dept_emp de
	on s.emp_no = de.emp_no
    where s.to_date = '9999-01-01'),
rank_salary as 
(select 
	emp_no,
    dept_no,
	salary,
    rank() over(partition by dept_no order by salary desc) as Rank_salary
from current_salary)
select
	concat(e.first_name, ' ',e.last_name) employ_name,
   r.Rank_salary,
   r.salary,
   d.dept_name
from rank_salary r
join employees e
	on r.emp_no= e.emp_no
join departments d
	on d.dept_no = r.dept_no
    where r.Rank_salary <= 3
    order by r.Rank_salary,d.dept_name;

-- ---------------------------Question 3 — Employees With No Salary Increase-------------------------------------
-- Which employees have only one salary record — meaning they never received a raise? Show emp_no and their salary.
with emp_count as 
	(select
    count(*) totat_emply,
    max(salary) as salary,
	emp_no
from salaries
	group by emp_no
    having count(*)  = 1)
select
	ec.emp_no,
    ec.salary,
    concat(e.first_name , ' ', e.last_name) as employ_name,
    datediff(curdate(), e.hire_date)  / 365  as years_employed
from emp_count ec
join employees e
	on ec.emp_no = e.emp_no
    order by years_employed desc;
    
-- ---------------------------------Question 4 — Gender Pay Gap Per Department-------------------------------------
-- What is the average salary for Male vs Female employees in each department? Show the difference in dollar amount.
with c_data as(
select 
	de.dept_no,
    s.salary,
    e.gender
from employees e
join salaries s
	on e.emp_no = s.emp_no
join dept_emp de
	on e.emp_no = de.emp_no),
avg_salary as 
(select
	dept_no,
    gender,
    avg(salary) salary
from  c_data
group by dept_no,gender),
pivot as (
select
	dept_no,
    round(max(case when av.gender = 'M' then av.salary end ),2) avg_male_salary,
    round(max(case when av.gender = 'F' then av.salary end ),2) avg_female_salary
from avg_salary av
group by dept_no)
select 
	d.dept_name,
    avg_male_salary,
    avg_female_salary,
	(avg_male_salary -  avg_female_salary) pay_gap,
    round(((avg_male_salary -  avg_female_salary)/avg_male_salary)*100.0,2) gap_percentage
from pivot p
join departments d
	on p.dept_no = d.dept_no
    order by pay_gap;
-- -------------------------------------Question 5 — Department Turnover--------------------------------------------------
-- Which departments have the most employees who have already left — meaning their to_date in dept_emp is not 9999-01-01?-

with empl_ternover as 
(select 
     d.dept_name,
     count(*) employ_left
from dept_emp de
join departments d
	on de.dept_no = d.dept_no
    where de.to_date <> 9999-01-01
group by d.dept_name 
)
select 
	dept_name,
    employ_left,
    rank()over(order by employ_left desc) rnk
from empl_ternover
order by employ_left desc
















