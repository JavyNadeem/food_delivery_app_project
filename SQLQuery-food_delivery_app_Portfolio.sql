create database food_delivery_app

drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

/* what is the total amount each customer spent on food deliver app? */
select s.userid, sum(p.price) total_price from sales s
inner join product p on s.product_id = p.product_id
group by s.userid

/* How many days each customer visited food delivery app?*/

select  userid, count(distinct created_date) as date_visited
from sales
group by userid

/* what was the first product purchased by each customer?*/

select * from 
(select *, Row_number() over (PARTITION by userid order by created_date) as ranks from sales) a
where ranks = 1

/* what is the most purchased item on the menu and how many times it was purchased by the customer?*/

select userid, count(product_id) purchases from sales where product_id = 
(	select Top 1 product_id  from sales 
	group by product_id
	order by COUNT(product_id) desc
)

group by userid

/* which item was most popular for each of the customer? */


select * from 
(select *, rank() over(PARTITION by userid order by totalcount desc) mostpopular from
(select userid, product_id, COUNT(product_id) as totalcount from sales group by userid,product_id)a)b
where mostpopular = 1

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;


/* which item was purchased first by the custoomer after they become the member? */

select * from 
(select *, rank() over(partition by userid order by created_date) as rnk from
(select s.userid, s.created_date, s.product_id, g.gold_signup_date from sales s join goldusers_signup g 
on s.userid = g.userid and created_date >= gold_signup_date) a)b
where rnk = 1

/* which item was purchased first by the customer just before they become the member? */

select * from 
(select *, rank() over(partition by userid order by created_date desc) as rnk from
(select s.userid, s.created_date, s.product_id, g.gold_signup_date from sales s join goldusers_signup g 
on s.userid = g.userid and created_date <= gold_signup_date) a)b
where rnk = 1

/* what is the total order and amount spent for each member before they become member? */

select userid, count(created_date) totalorder, sum(price) totalspent from
(select a.*, p.price from 
(select s.userid, s.created_date, s.product_id, g.gold_signup_date from sales s join goldusers_signup g 
on s.userid = g.userid and created_date <= gold_signup_date) a inner join product p on a.product_id = p.product_id) q
group by userid


/* if buying each product generates points for eg 5rs= 2 zomato points and each product has different purchaisng points 
for eg p1 5r = 1 zomato point, for p2 rs 10 = 5 zomato points and p3 5rs = 1 zomato point, 
calculate teh points collected by each customer and for which product most of the points have been give till now? */

----points collected by each user-----
select userid, sum (totalpoints) pointsearned from
(select d.*, price/points as totalpoints from
(select b.*, case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select userid, sum(price) price, product_id from
(select sales.userid, sales.created_date, product.price, product.product_id
from sales inner join product 
on sales.product_id = product.product_id) q
group by userid, product_id)b)d)e
group by userid

-------Product with highest points -----

select * from
(select *, rank() over(order by totalpoints desc) as highestproduct from
(select product_id, sum (totalpoints) totalpoints from
(select d.*, price/points as totalpoints from
(select b.*, case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from
(select userid, sum(price) price, product_id from
(select sales.userid, sales.created_date, product.price, product.product_id
from sales inner join product 
on sales.product_id = product.product_id) q
group by userid, product_id)b)d)e
group by product_id) f)g
where highestproduct = 1

/* In the first one year after the customer joins the gold program (including their join date) irrespective of 
what the customer has purchased they earn 5 zomato points for every 10rs spent 
who earned more 1 or 3 and what was their points earning in their first years? */


select x.* from
(select r.*, rank() over(order by price desc) rnk from
(select d.userid, sum(price) price ,sum(points) totalpoints from
(select t.*, case when product_id = 1 then 2 when product_id = 2 then 2 when product_id = 3 then 2 else 0 end as points from
(select sales.userid, sales.created_date, sales.product_id, g.gold_signup_date, product.price from sales inner join goldusers_signup g
ON sales.userid = g.userid
  inner join product
ON sales.product_id = product.product_id
and created_date > = gold_signup_date)t)d
group by userid)r) x
where rnk = 1

select x.* from
(select r.*, rank() over(order by price desc) rnk from
(select v.*, price*totalpoints as totalearned from
(select d.userid, sum(price) price ,sum(points) totalpoints from
(select t.*, case when product_id = 1 then 0.5 when product_id = 2 then 0.5 when product_id = 3 then 0.5 else 0 end as points from
(select sales.userid, sales.created_date, sales.product_id, g.gold_signup_date, product.price from sales inner join goldusers_signup g
ON sales.userid = g.userid
inner join product
ON sales.product_id = product.product_id
and created_date > = gold_signup_date and created_date <= dateadd(year,1,gold_signup_date) ) t)d
group by userid)v)
r) x
where rnk = 1

/* rank all the transactions of the customers */

select *, rank() over (partition by userid order by created_date) rnk from sales


/* rank all the transactions of each member whenever they are a zomato gold member for every non gold member transaction mark as na */

select x.*, case when rnk = 0 then 'na' else rnk end as rnkfinla from
(select q.*, cast((case when gold_signup_date is null then 0 else rank() over (partition by userid order by created_date desc) end) as varchar) rnk from
(select sales.userid, sales.created_date, sales.product_id, g.gold_signup_date from sales left join goldusers_signup g
on sales.userid = g.userid and created_date > = gold_signup_date)q)x
