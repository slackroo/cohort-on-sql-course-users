select country,source,phone_type, count(*) from registrations
group by country,source,phone_type 
order by count desc;

select country,source,phone_type, count(*) from (
select * from free_tree
join registrations
on free_tree.user_id = registrations.user_id)as joined_free
group by country,source,phone_type
order by count desc;

select country,source,phone_type, count(*) from (
select * from super_tree
join registrations
on super_tree.user_id = registrations.user_id)as joined_free
group by country,source,phone_type
order by count desc;


select * from registrations
limit 100;

-- revenue form invitations
SELECT SUM(ttl) AS total_revenue
FROM (;

SELECT super.user_id,
       COUNT(*) AS ttl
FROM (SELECT super_tree.user_id,
             registrations.source
      FROM super_tree
        JOIN registrations ON super_tree.user_id = registrations.user_id) AS super
WHERE source = 'invite_a_friend'
GROUP BY super.user_id
ORDER BY ttl DESC;

)
AS
tab_big;


select source, sum(rev) from(
select super_tree.user_id, registrations.source, count(*)-1 as rev from super_tree
join registrations
on super_tree.user_id = registrations.user_id
group by super_tree.user_id, registrations.source) as big_t
group by source;
limit 100;

-- What's the total revenue for Android users, from Brazil, from the invitation program?
SELECT big_t.source,
       big_t.phone_type,
       big_t.birth_year,
       SUM(rev)
FROM (SELECT super_tree.user_id,
             registrations.source,
             registrations.phone_type,
             registrations.birth_year,
             COUNT(*) -1 AS rev
      FROM super_tree
        JOIN registrations ON super_tree.user_id = registrations.user_id
      WHERE country = 'brazil'
      AND   phone_type = 'android'
      GROUP BY super_tree.user_id,
               registrations.source,
               registrations.birth_year,
               registrations.phone_type) AS big_t
GROUP BY big_t.source,
         big_t.phone_type,
         big_t.birth_year
ORDER BY SUM DESC;

-- Alternative solution

select source, count(*) - count(distinct(super_tree.user_id))as revenue from super_tree
join registrations 
on super_tree.user_id = registrations.user_id
group by source;
limit 10;

-- Daily active users
select count(distinct(user_id)) from 
  (select * from free_tree
  union all
  select * from super_tree) as super_free
where my_date = ' 2021-04-24';

-- Daily Revenue
--group A where yesterday was their first super tree sends
select user_id,min(my_date)  from super_tree
group by user_id
Having min(my_date) = '2021-04-24';


-- group b users where they have sent a super tree long back ie before yesterday
select user_id,min(my_date)  from super_tree
group by user_id
Having min(my_date) < '2021-04-24';
limit 10;

--daily evenue
select(

-- how to get no of super tree sends by user_id(yesterday only)

select sum(super_tree_sends) from 
  (select user_id,min(my_date)  from super_tree
  group by user_id
  Having min(my_date) = '2021-04-24')as yesterday_registered
join
  (select user_id, count(*)-1 as super_tree_sends from super_tree
  where my_date = '2021-04-24'
  group by user_id)as yesterday_sends
on yesterday_sends.user_id = yesterday_registered.user_id  )

+

-- how to get no of super tree send by user_id(yesterday only
(
select sum(super_tree_sends) from 
  (select user_id,min(my_date)  from super_tree
  group by user_id
  Having min(my_date) < '2021-04-24') as before_yest_registrations
join
  (select user_id, count(*) as super_tree_sends from super_tree
  where my_date = '2021-04-24'
  group by user_id)as yesterday_sends
on yesterday_sends.user_id = before_yest_registrations.user_id 
) ;
select(
select count(*) - count(distinct(user_id))
from super_tree
where my_date < '2021-04-24')-
(
select count(*) - count(distinct(user_id))
from super_tree
where my_date < '2021-04-23') ;


select my_date,  count(*) from(
SELECT
    my_date, 
    user_id, 
    ROW_NUMBER() OVER (PARTITION BY user_id order by my_date desc ) as nth_super_tree
  FROM 
    super_tree) as r
    where r.nth_super_tree != 1
    group by r.my_date
    order by r.my_date desc;

SELECT CASE
         WHEN min_date_q.min_date = super_tree.my_date THEN COUNT(*) -1
         ELSE COUNT(*)
       END AS count_all,
       my_date,
       user_id,
       min_date
FROM super_tree
join(
select user_id as usr_min, min(my_date)as min_date from super_tree
group by user_id)as min_date_q 
on super_tree.user_id = usr_min
group by my_date,
       user_id,
       min_date
;


SELECT my_date,
       SUM(count_all)
FROM (SELECT CASE
               WHEN min_date_q.min_date = super_tree.my_date THEN COUNT(*) -1
               ELSE COUNT(*)
             END AS count_all,
             my_date,
             user_id,
             min_date
      FROM super_tree
        JOIN (SELECT user_id AS usr_min,
                     MIN(my_date) AS min_date
              FROM super_tree
              GROUP BY user_id) AS min_date_q ON super_tree.user_id = usr_min
      GROUP BY super_tree.my_date,
               super_tree.user_id,
               min_date) AS count_em
GROUP BY my_date;

-- funnel analysis
--- funnel registrations
SELECT reg.my_date,
       reg.source,
       reg.phone_type,
       reg.reg_funnel,
       free_users.free_funnel,
       super_user.super_funnel,
       paid_user.paid_funnel
FROM (;SELECT my_date,
             phone_type,
             source,
             COUNT(*) AS reg_funnel
      FROM registrations
      GROUP BY my_date,
               phone_type,
               source
      ORDER BY my_date, phone_type
               ;) AS reg
  LEFT JOIN (


--funnel free_tree
  SELECT registrations.my_date,
       registrations.phone_type,
       registrations.source,
       COUNT(DISTINCT (free_tree.user_id)) AS free_funnel
FROM free_tree
  JOIN registrations ON free_tree.user_id = registrations.user_id
GROUP BY registrations.my_date,
         registrations.phone_type,
         registrations.source
ORDER BY registrations.my_date
         ) AS free_users ON free_users.my_date = reg.my_date AND reg.phone_type = free_users.phone_type AND reg.source = free_users.source LEFT JOIN (


--funnel super_tree
  SELECT registrations.my_date,
       registrations.phone_type,
       registrations.source,
       COUNT(DISTINCT (super_tree.user_id)) AS super_funnel
FROM super_tree
  JOIN registrations ON super_tree.user_id = registrations.user_id
GROUP BY registrations.my_date,
         registrations.phone_type,
         registrations.source
ORDER BY registrations.my_date
         ) AS super_user ON super_user.my_date = reg.my_date AND reg.phone_type = super_user.phone_type AND reg.source = super_user.source
 LEFT JOIN (
--funnel super_tree (paid)
 SELECT registrations.my_date,
       registrations.phone_type,
       registrations.source,
       COUNT(paying_users.user_id) AS paid_funnel
FROM (SELECT user_id,
             COUNT(distinct(user_id))
      FROM super_tree
      GROUP BY user_id
      HAVING COUNT(*) > 1) AS paying_users
  JOIN registrations ON paying_users.user_id = registrations.user_id
GROUP BY registrations.my_date,
         registrations.phone_type,
         registrations.source
ORDER BY registrations.my_date
         ) AS paid_user ON paid_user.my_date = reg.my_date AND reg.phone_type = paid_user.phone_type AND reg.source = paid_user.source;




(;select user_id, count(*) from super_tree
group by user_id
having count(*) > 1
order by user_id
;


select user_id, count(distinct(user_id)) from super_tree
where my_date = '2020-10-09'
group by user_id
;
