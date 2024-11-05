-- case study 
use school;
select * from employees;

-- delete the duplicate rows from the datas 
delete from employees where id in 
(
	select id  from
	(
	select id, row_number() over( partition by first_name , last_name order by id ) as 'rnk' from employees
	)k where rnk>1
);

-- question number 2 
-- 2  You sales manager and you have 3 territories under you,   the manager decided that for each territory the salesperson who have  sold more than 30%  of the average of that 
-- territory  will  get  hike  and person who have done 80% less than the average salary will be issued PIP , now for all you have to  tell your manager if he/she will 
-- get a hike or will be in a PIP

select * from sales;

-- store the values in the variables 
set @a= (select round(avg(sales),2) as average_a from sales where territory= 'A');
set @b= (select round(avg(sales),2) as average_b from sales where territory= 'B');
set @c= (select round(avg(sales),2) as average_c from sales where territory= 'C');

select @a,@b,@c;  -- curent control + enter shortcut cut key to executes 

select *,
     case when sales>1.3*territory_mean  then  'HIKE'  -- more than 30 % 
          WHEN sales <0.8*TERRITORY_MEAN then 'PIP'  -- less than 80 %  
	      else 'Same parameter'
		end as 'Final decision'
	from
    (
			SELECT *,
				CASE WHEN territory = 'A' THEN @a
					 WHEN territory = 'B' THEN @b
					 WHEN territory = 'C' THEN @c
					 ELSE NULL
				END AS territory_mean
			FROM sales
	)k	;
    
 
/* 3. You are database administrator for a university , University have declared result for a special exam , However children were not happy with the marks as marks were
not given appropriately
and many students marksheet was blank , so they striked. Due to strike univerisity again checked the sheets and updates were made. Handle these updates*/

select * from students;
-- add and updates the datas 

--  updates tables 
select * from std_updates;  -- sophia and tom needs to be updated but there is existing some of the different columns

-- We have to deal this in two ways , existing ko update karna , aur new ko add karna


SET SQL_SAFE_UPDATES = 0;

update  students as s
inner join
std_updates as t
set s.marks= t.marks
where s.roll= t.roll;


select * from students;  -- roll , s_name , Marks 
select * from std_updates; -- roll s_name , marks 

-- joins examples 
-- this will provides the common data in both tables 

-- modify this fiormulas 

  select s.s_name,s.marks,u.marks from students as s inner join std_updates as u on s.roll=u.roll;
 
 -- updation done  -- this will upodate the data from one table from another tables 
update  students as s
inner join
std_updates as t
set s.marks= t.marks
where s.roll= t.roll;

-- Addition of the new datas 
INSERT INTO students (roll, s_name, marks)
SELECT  roll, s_name, marks
FROM (
    SELECT s.roll AS rl, t.*
    FROM students AS s
    RIGHT JOIN std_updates AS t ON s.roll = t.roll
) k
WHERE rl IS NULL;


-- query break down
-- this will give us the new datas  -- right join the data to give the nukll values 
SELECT  roll, s_name, marks  -- this will fetch the data of the only data from the updates tables 
FROM (
    SELECT s.roll AS rl, t.*    -- existing data not null new daata null values 
    FROM students AS s
    RIGHT JOIN std_updates AS t ON s.roll = t.roll
) k
WHERE rl IS NULL;

-- we have to truncate the std_updates tabkles 

Truncate table students;
select * from students;  -- sophia and tom has to be updated   sophia 45 tom 55 
select * from std_updates ;  -- sopiha  75 tom 85 

DELIMITER //
CREATE PROCEDURE ProcessUpdatesAndInserts()
BEGIN
    -- Update existing records
    UPDATE students AS s
    INNER JOIN std_updates AS t ON s.roll = t.roll
    SET s.marks = t.marks;

    -- Insert new records
    INSERT INTO students (roll, s_name, marks)
    SELECT roll, s_name, marks
    FROM (
        SELECT s.roll AS rl, t.*
        FROM students AS s
        RIGHT JOIN std_updates AS t ON s.roll = t.roll
    ) k
    WHERE rl IS NULL;

    -- Truncate the std_updates table
    TRUNCATE TABLE std_updates;
END //
DELIMITER ;


-- droping the procedures 
-- drop PROCEDURE ProcessUpdatesAndInserts;

select * from students;  -- sophia 45 , tom 55
select count(*) from students; -- 15 students 
select * from std_updates;  -- sophia 75 tom 85     --7 5 data should be updated 
select count(*) from std_updates ;

-- calling the procedures 
call ProcessUpdatesAndInserts();

select * from students;
select count(*) from students;
select * from students;



-- 6  -- create a system where it will check the warehouse before making the sale and if sufficient quantity is avaibale make the sale and store the sales transaction 
 -- else show error for insufficient quantity.( like an ecommerce website, before making final transaction look for stock.)

select * from sales;

select * from products;
select * from saless; -- order_id, order_date, product_code , quantity_sold, per_quantity_price, total_sale_price

DELIMITER //
CREATE PROCEDURE MakeSale(IN pname VARCHAR(100),IN quantity INT)
BEGIN
    set @co = (select product_code from products where product_name= pname);
    set @qu = (select Quantity_remaining from products  where product_code= @co);
    set @pr = (select price from products where product_code= @co);
    IF quantity <=  @qu THEN
        INSERT INTO saless(order_date, product_code, Quantity_sold, per_quantity_price , total_sale_price)
        VALUES (CURRENT_DATE(), @co, quantity,@pr, quantity* @pr);
        SELECT 'Sale successful' AS message; -- Output success message
        update products
          set quantity_remaining = quantity_remaining - quantity,
            Quantity_sold= Quantity_sold+quantity
		where  product_name = pname;
	ELSE
        SELECT 'Insufficient quantity available' AS message;
	END IF;
    
    END //
DELIMITER ;

drop procedure MakeSale;

 -- call makesale ('Rolex Submariner', 4)
select * from saless;
select * from products;
call makesale('Rolex Submariner',10);

  
 
  -- 7 you have a table where there is sales data for entire month you have to calculate cumultive sum for the entire  month data  show it month wise and week wise both	
select * from salesss;  -- sale_date , day_of_week , sales_amount

-- break downs 
select sale_date,sum(sales_amount)  over (order by sale_date) as running_sum from salesss; -- sale_date, running_sum
  
select sale_date, day_of_week, sales_amount from salesss; -- sale_date, day_of_week , sales_amount

select s.sale_date, day_of_week, sales_amount, running_sum from  salesss as s
inner join
(
select sale_date,sum(sales_amount)  over (order by sale_date) as running_sum from salesss  -- cumulkative sums 
)k on s.sale_date=k.sale_date;


-- for each week closing

select * from (
  select s.sale_date, day_of_week, sales_amount, running_sum from  salesss as s
  inner join
  (
  select sale_date,sum(sales_amount)  over (order by sale_date) as running_sum from salesss  -- cumulkative sums 
  )k on s.sale_date=k.sale_date) m where day_of_week= 'Friday';
  
  -- end of question number 7 
  
   -- 8 Given a Sales table containing SaleID, ProductID, SaleAmount, and SaleDate, write a SQL query to find the top  2 salespeople based on
  -- their total sales amount for the current month. If there's a tie in sales amount, prioritize the salesperson with the earlier registration date.

select * from salessss;
select salespersonId, sum(saleamount)as summ, min(Sale_man_registration_date) as mindate 
 from salessss where year(saledate)=2024 and month(saledate) = 5 group by salespersonid
order by summ desc , mindate 
limit 3;
  

-- 9 You have got transaction data in the format  transaction id , date , type , amount and description , howvevrr this format is not
 -- easily interpretable , now you have to make it in the good format ( month , year, revenue, expenditure, profit)

DELIMITER //
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    transaction_date DATE,
    transaction_type VARCHAR(50),
    amount DECIMAL(10, 2),
    descriptions varchar(1000)
);
// DELIMITER 

select * from transactions;  --  month , year, revenue, expenditure, profit

select month(transaction_date)  as months , year(transaction_date) as years,
sum(case when transaction_type ='Revenue'  then amount else 0 end ) as total_revenue,
sum(case when transaction_type ='Expense'  then amount else 0 end ) as total_expenses,
sum(case when transaction_type ='Revenue'  then amount else 0 end )- sum(case when transaction_type ='Expense'  then amount else 0 end ) as net_profit
from 
transactions 
group by 
   year(transaction_date), month(transaction_date)
order by  months;
    
-- break down the query
select * ,month(transaction_date)  as 'months' , year(transaction_date) as 'years',
sum(case when transaction_type ='Revenue'  then amount else 0 end ) as 'total_revenue'
from transactions group by month(transaction_date);

-- break downs 
select month(transaction_date)  as months , year(transaction_date) as years,
case when transaction_type ='Revenue'  then amount else 0 end  as total_revenue,
case when transaction_type ='Expense'  then amount else 0 end  as total_expenses
from 
transactions 
group by years, months
order by  months;

-- breaks

select month(transaction_date)  as months , year(transaction_date) as years,
max(case when transaction_type ='Revenue'  then amount else 0 end ) as total_revenue,
max(case when transaction_type ='Expense'  then amount else 0 end ) as total_expenses,
max(case when transaction_type ='Revenue'  then amount else 0 end )- sum(case when transaction_type ='Expense'  then amount else 0 end ) as net_profit
from 
transactions 
group by 
   year(transaction_date), month(transaction_date)
order by  months;


select max(amount) as amt from transactions where month(transaction_date)=1 and year(transaction_date)=2024 
and transaction_type='Expense';


-- 5 You have a table that stores student information  roll number wise , now some of the students have left the school due to which the  roll numbers became discontinuous
-- Now your task is to make them continuous.

 select * from studentss;
 
-- delete some datas 
delete from studentss where roll_number in (3,4,5,6);
 
 
select *, row_number() over ( order by roll_number) as roll from studentss ;

update  studentss as s                                                  -- step 2 and 3
inner join
(
 select *, row_number() over ( order by roll_number) as roll from studentss 
)k 
on s.roll_number = k.roll_number 
set s.roll_number = k.roll;

select * from studentss;


 -- You have  to make a procedure , where you will give 
-- 3 inputs string, deliminator  and before and after  command , based on the   information provided you have to 
-- find that part of string.


select length("Ajay Giri");  -- include space also
DELIMITER //
create function string_split( s varchar(100), d varchar(5), c varchar (10))
returns Varchar(100)
DETERMINISTIC
begin
     set @l = length(d);  -- deliminator can be of any length.
     set @p = locate(d, s);
     set @o = 
        case  when c like '%before%'
            then left(s,@p)
        else 
            substring(s, @p+@l,length(s))
		end;
  return @o;
end //
DELIMITER ;

select * , string_split(emp_name , ' ', 'after') from employeess;
select * , string_split(emp_name , ' ', 'before') from employeess;












