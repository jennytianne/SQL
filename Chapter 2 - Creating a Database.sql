select now(); 
show character set; 
show tables; 

desc customer; 


/* Chapter 2: Create Tables that show the name, gender, birthdate, address, and favorite foods of people */ 
create table person 
(person_id int unsigned not null auto_increment, 
fname varchar(40), 
lname varchar(40), 
gender enum('M', 'F'), 
birthdate  date, 
street varchar(50), 
city varchar(40), 
state char(2), 
country varchar(40), 
constraint pk_person primary key (person_id)
); 


desc person;


create table favorite_food
(person_id int unsigned, 
food varchar(40), 
constraint pk_food primary key (person_id, food), 
constraint fk_food foreign key (person_id) 
	references person (person_id)
); 

desc favorite_food; 
 
 
/* Insert */ 
insert into person
(person_id, fname, lname, gender, birthdate) 
values (null, 'Jenny', 'Tian', 'F', '1996-02-23'); 

insert into favorite_food (person_id, food) 
values (1, 'nachos'); 
insert into favorite_food (person_id, food) 
values (1, 'bananas'); 

/* Update */
update person 
set birthdate = str_to_date('DEC-21-2001', '%b-%d-%Y'), 
street = '3117 Broadway', 
city = 'New York', 
state = 'NY', 
country = 'USA'
where person_id = 1; 


/* Select */ 
select A.*, B.* 
from person as A 
left join favorite_food as B 
on A.person_id = B.person_id
where A.person_id = 1 ; 


/* Delete */ 
delete from favorite_food 
where food = 'nachos'; 

select * from favorite_food; 

/* Drop table */ 
drop table favorite_food; 
drop table person; 
