-- A subquery is a select statement /query contained in another SQL statement. 
-- Enclosed within parentheses and usually executed before the containing statement. 
-- A temporary table: after containing statement finishes execution, the subquery results are discarded.
-- Types: 
-- - Uncorrelated: 
-- 	- single row and single column / scaler subquery: equality <>, =, >, <
-- 	- multi-row and single column: in, not in, all, any 
--  - multi-column: in
-- - Correlated (references cols from containing statement):
-- 	- exists
-- - Subqueries can function as: 
-- 	- data creation/data sources: from (subqueries must be uncorrelated, bc they're executed first)
--  - filtering conditions: where, having, order by 
--  - expression generators: select 

show tables; 

/* all accounts not opened by the head teller at Woburn branch */ 
select account_id, product_cd, cust_id, avail_balance 
from account 
where open_emp_id != (select e.emp_id 
	from employee e inner join branch b 
    on e.assigned_branch_id = b.branch_id 
    where e.title = 'Head Teller' and b.city = 'Woburn')
;

/* all employees that supervise other employees */ 
select e.emp_id, e.fname, e.lname, e.title 
from employee e
where exists 
(select 1 from employee m where e.emp_id = m.superior_emp_id)
; 

select emp_id, fname, lname, title 
from employee 
where emp_id in (select superior_emp_id from employee); 

select emp_id, fname, lname, title 
from employee 
where emp_id = any(select superior_emp_id from employee); 

select distinct m.superior_emp_id, e.fname, e.lname, e.title 
from employee e
inner join employee m 
on e.emp_id = m.superior_emp_id ; 

/* All accounts having avail balance greater than any of Frank Tucker's accounts */ 

select * from account 
where avail_balance > any(
select avail_balance from account 
where cust_id = 
(select cust_id 
from individual 
where fname = 'Frank' and lname = 'Tucker')); 

select * from account 
where avail_balance > any(
select a.avail_balance from account a
inner join individual i 
on a.cust_id = i.cust_id
where i.fname = 'Frank' and i.lname = 'Tucker'); 

/* Check the available and pending balances of an account against the transactions 
logged against the account */ 



/* all accounts that have at least one transaction on '2000-01-15' */ 
select a.* from account a
where exists (select 1 from transaction t 
where a.account_id =  t.account_id 
and t.txn_date = '2000-01-15'); 


/* Modify last_activity_date in account table with the recent transaction date, for accounts that have transactions */ 
update account a 
set a.last_activity_date =  
(select max(t.txn_date) 
from transaction t 
where t.account_id = a.account_id ) 
where exists (select 1 from transaction t 
where a.account_id =  t.account_id); 

/* Count the number of customers that have available balances in their accounts in each balance group  */ 

select b.name, count(cust_rollup.cust_id) as cust_count
from 
(select a.cust_id, sum(a.avail_balance) as cust_balance 
from account a
where a.product_cd in (select product_cd from product where product_type_cd = 'ACCOUNT')
group by a.cust_id) cust_rollup
inner join 
(select 'Small' name, 0 low_limit, 4999.99 high_limit 
union all 
select 'Medium' name, 5000 low_limit, 9999.99 high_limit 
union all 
select 'Large' name, 10000 low_limit, 9999999.99 high_limit) b 
on cust_rollup.cust_balance between b.low_limit and b.high_limit 
group by b.name; 

/* find the employee responsible for opening the most accounts */ 
select open_emp_id, count(*) as account_num 
from account 
group by open_emp_id 
having count(*) = (select max(a.account_num) from 
(select open_emp_id, count(*) as account_num 
from account 
group by open_emp_id ) a ); 

/* find all loan accounts in the account table */ 
select account_id 
from account 
where product_cd in (select product_cd from product where product_type_cd = 'LOAN');

select a.account_id 
from account a 
where exists (select 1 from product p
 where p.product_type_cd = 'LOAN' and a.product_cd = p.product_cd); 

/* employees' and their bosses' full names sorted by lname of employee's boss and lname of employee */ 
select e.emp_id, concat(e.fname, ' ', e.lname) as emp_name, 
(select concat(m.fname, ' ', m.lname)  from employee as m
where m.emp_id = e.superior_emp_id)  as boss_name
from employee e 
order by (select m.lname from employee as m where m.emp_id = e.superior_emp_id) 
, e.lname; 

/* customers with exactly two accounts */ 
select c.cust_id, c.cust_type_cd, c.city 
from customer c 
where 2 = (select count(*) from account a where a.cust_id = c.cust_id); 

select c.cust_id, c.cust_type_cd, c.city 
from customer c 
inner join (select a.cust_id, count(a.account_id) from account a group by a.cust_id having count(a.account_id) = 2) count 
on c.cust_id =  count.cust_id ; 



/* sum deposit accounts balances by account type, employoee and branch */ 

/* subquery as expressions , use correlated subqueries with the main table */ 
select 
(select p.name from product p where p.product_cd = a.product_cd and p.product_type_cd = 'ACCOUNT') product_name, 
(select b.name from branch b where b.branch_id = a.open_branch_id) branch_name,
(select concat(e.fname, ' ', e.lname) from employee e where e.emp_id = a.open_emp_id) emp_name, 
sum(a.avail_balance) as tot_deposits
from account a
group by 1, 2, 3
order by 1, 2, 3; 

/* inner join with the main table */ 
select p.name as product_name, b.name as branch_name, concat(e.fname, ' ', e.lname) as emp_name, 
sum(a.avail_balance) as tot_deposits 
from account a 
inner join product p 
on a.product_cd = p.product_cd
inner join branch b 
on a.open_branch_id = b.branch_id 
inner join employee e 
on a.open_emp_id = e.emp_id 
where p.product_type_cd = 'ACCOUNT'
group by 1, 2, 3
order by 1, 2; 

/* group by as a subquery to create the summed deposits, and then merge in the other names  */ 
select  p.name as product_name, b.name as branch_name, concat(e.fname, ' ', e.lname) as emp_name, g.tot_deposits
from (select product_cd, open_branch_id, open_emp_id, sum(avail_balance) as tot_deposits 
from account 
group by product_cd, open_branch_id, open_emp_id) g
inner join product p on g.product_cd = p.product_cd and p.product_type_cd = 'ACCOUNT'
inner join branch b on g.open_branch_id = b.branch_id 
inner join employee e on e.emp_id = g.open_emp_id; 

