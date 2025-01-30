-- Netflix Project

CREATE TABLE IF NOT EXISTS netflix
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);

--1.Count the number of Movies vs TV Shows
--v1
select type, count(*) as num_of_each_type
from netflix
group by type
-- v2
select distinct count(*) over(partition by type), type
from netflix

 
--2.Find the most common rating for movies and TV shows
-- for each
 select * from (
 with cte as (
select count(*) as rating_amount, rating, type
from netflix 
group by rating, type
)
select *, rank() over(partition by type order by rating_amount  desc ) from cte
)where rank =1

--The most common rating for both
with cte as(
select count(*) amount, rating
from netflix
group by rating
)
select * from cte
where amount = (select max(amount) from cte)




--3. List all movies released in a specific year (e.g., 2020)

select * from
netflix
where release_year = 2020



--4. Find the top 5 countries with the most content on Netflix
with cte as(select count(*) content_num,  country
from netflix
group by country
having country LIKE '%'|| country ||'%')
select * from 
cte 
where country not like '%,%'



--5. Identify the longest movie
select * from 
netflix
where duration in (select max(duration) from netflix)


 
--6. Find content added in the last 5 years
select * 
from netflix
where extract(year from age(now())) -EXTRACT (YEAR FROM AGE(date_added::date)) <= 5




--7. Find all the movies/TV shows by director 'Mike Flanagan'!
select *
from netflix
where director = 'Mike Flanagan'




--8. List all TV shows with more than 5 seasons
select * 
from netflix
where duration like '%Seasons%' and duration <> '1 Seasons' and duration <> '2 Seasons' and duration <> '3 Seasons' and duration <> '4 Seasons'

--v2

select * 
from netflix
where cast(SPLIT_PART(duration, ' ', 1) as integer) >= 5 and duration like '%Seasons%'



--9. Count the number of content items in each genre
select count(*) content_amount, genre
from(
select unnest(string_to_array(listed_in, ', ')) as genre
from netflix
) group by genre




--10.Find each year and the average numbers of content release in Germany on netflix. 
--return top 5 year with highest avg content release!
with cte as (select *, rank() over(order by average_release desc) 
from (
select count(*) as release_num, release_year, count(*) / sum(count(*)) over() as average_release
from netflix
--where country = '---'
group by release_year, country
having country = 'Germany'
))
select * from cte where rank <=5




--11. List all movies that are documentaries
-- including other sub_genres apart from documentaries
select * 
from netflix
where type = 'Movie' and listed_in like '%Documentaries%'

-- only documentaries
select * 
from netflix
where type = 'Movie' and listed_in = 'Documentaries'



--12. Find all content without a director
select * 
from netflix
where director is null




--13. Find how many movies actor 'Mia Goth' appeared in last 10 years.
select count(*)
from netflix
where casts like '%Mia Goth%' and extract(year from age(now())) - release_year <=10




--14. Find the top 10 actors who have appeared in the highest number of movies produced in United Kingdom.
select *
from (select distinct actor_in_Indmov, starred_amount, rank() over(order by starred_amount desc) from (
with cte as(select unnest(string_to_array(casts, ', ')) as actor_in_Indmov
from netflix 
where country = 'United Kingdom')
select count(*) as starred_amount,  actor_in_Indmov
from cte
group by actor_in_Indmov
)
) where rank <=10
order by rank asc




--15.Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
--the description field. Label content containing these keywords as 'Bad' and all other 
--content as 'Good'. Count how many items fall into each category
create or replace view view_bad as (
(
select *, count(*)  over() as bad from (
select * from netflix
where description like '%violence%' or description like '%kill%')))
create or replace view view_good as (select *, count(*) over() as good 
from netflix
where description not in (select description from (select *, count(*)  over() as bad from (
select * from netflix
where description like '%violence%' or description like '%kill%'))))

select distinct n.*, coalesce(b.bad,0) as bad, coalesce(g.good, 0)as good from 
netflix n left join view_bad b on n.show_id = b.show_id left join view_good g on g.show_id = n.show_id

---    ---    ----      ----------        -----      -----       ------         ----------   ------  ----
