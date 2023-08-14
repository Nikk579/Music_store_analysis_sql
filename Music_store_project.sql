select * from invoice

--  Q1: Who is the senior most employee based on job title?

select * from employee
order by levels desc
limit 1

-- Q2: Which are the top 5 countries who have the most Invoices?
  select count(*) as total_counts , billing_country
  from invoice
  group by billing_country
  order by total_counts desc
  limit 5
  
--    What are top 3 values of total invoice?
   select total from invoice 
   order by total desc 
   limit 3
   
  /* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select billing_city , sum(total) as invoice_total
from invoice 
group by billing_city 
order by invoice_total desc

  /* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
  Write a query that returns the person who has spent the most money.*/
  
  select customer.customer_id , first_name , last_name , sum(total) as total_spent
  from customer
  join invoice
  on customer.customer_id = invoice.customer_id
	group by customer.customer_id
	order by total_spent desc 
	limit 1;
	
-- 	Moderate Set 
	
/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

SELECT DISTINCT customer.email,customer.first_name, customer.last_name 
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;


/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT artist.artist_id ,artist.name ,count(artist.artist_id) as number_of_songs
from artist
join album on artist.artist_id = album.artist_id
join track on album.album_id = track.album_id
join genre on track.genre_id=genre.genre_id
where genre.name like 'Rock'
group by artist.artist_id
order by number_of_songs desc
limit 10


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT name , milliseconds
from track 
where milliseconds > (
	 select avg(milliseconds) as avg_song_length
	from track)
 order by milliseconds desc;
	
	
/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

select ar.artist_id,cust.first_name , cust.last_name , ar.name as artist_name ,
sum(il.unit_price* il.quantity) as total_spent
from invoice_line as il
join invoice as i on il.invoice_id=i.invoice_id
join customer as cust on i.customer_id=cust.customer_id
join track as tr on il.track_id=tr.track_id
join album as al on tr.album_id =al.album_id
join artist as ar on al.artist_id=ar.artist_id
group by 1,2,3,4
order by 5 desc 
limit 5;


-- this is for the best selling artist top 5 purchasing customers

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC
limit 5;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Method : Using CTE(common expression table) */

with popular_music_genre as (
	select count(invoice_line.quantity) as purchases ,customer.country,genre.name as genre_name , genre.genre_id ,
	ROW_NUMBER()OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
	from invoice_line
	
	join invoice as i on invoice_line.invoice_id=i.invoice_id
	join customer on i.customer_id= customer.customer_id
	join track on invoice_line.track_id= track.track_id
	join genre on track.genre_id=genre.genre_id
	group by 2,3,4
	order by 2 , 1 desc
)
select * from popular_music_genre where Rowno <=1



/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Method : using recursive method */

WITH RECURSIVE 
	customer_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customer_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customer_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;


/* Method : using CTE method */	
	
	WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1