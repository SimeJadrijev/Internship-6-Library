CREATE TABLE Libraries (
    LibraryID SERIAL PRIMARY KEY,
    LibraryName VARCHAR(255) NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL
);

CREATE TABLE Countries (
    CountryID SERIAL PRIMARY KEY,
    CountryName VARCHAR(255) NOT NULL,
    Population INT NOT NULL,
    AverageSalary DECIMAL(10, 2) NOT NULL
);

ALTER TABLE Countries
ALTER COLUMN AverageSalary TYPE FLOAT;


CREATE TABLE Genders (
    GenderID SERIAL PRIMARY KEY,
    GenderName VARCHAR(10) NOT NULL
);

ALTER TABLE Genders
ALTER COLUMN GenderName TYPE VARCHAR(30);

CREATE TABLE Authors (
    AuthorID SERIAL PRIMARY KEY,
    AuthorName VARCHAR(255) NOT NULL,
    DateOfBirth DATE NOT NULL,
    CountryID INT REFERENCES Countries(CountryID),
    GenderID INT REFERENCES Genders(GenderID)
);

ALTER TABLE Authors
DROP COLUMN Name;

ALTER TABLE Authors
ADD COLUMN AuthorName VARCHAR(255) NOT NULL,
ADD COLUMN Surname VARCHAR(255) NOT NULL;


CREATE TABLE BookTypes (
    BookTypeID SERIAL PRIMARY KEY,
    TypeName VARCHAR(50) NOT NULL
);

CREATE TABLE Books (
    BookID SERIAL PRIMARY KEY,
    Title VARCHAR(255) NOT NULL,
    PublicationDate DATE NOT NULL,
    BookTypeID INT REFERENCES BookTypes(BookTypeID)
);

CREATE TABLE BookInstances (
    InstanceID SERIAL PRIMARY KEY,
    BookID INT REFERENCES Books(BookID),
    LibraryID INT REFERENCES Libraries(LibraryID),
    InstanceCode VARCHAR(20) NOT NULL
);

CREATE TABLE Users (
    UserID SERIAL PRIMARY KEY,
    UserName VARCHAR(255) NOT NULL
);

CREATE TABLE BookLoans (
    LoanID SERIAL PRIMARY KEY,
    InstanceID INT REFERENCES BookInstances(InstanceID),
    UserID INT REFERENCES Users(UserID),
    LoanDate DATE NOT NULL,
    DueDate DATE NOT NULL
);


CREATE TABLE Authorship (
    AuthorshipID SERIAL PRIMARY KEY,
    AuthorID INT REFERENCES Authors(AuthorID),
    BookID INT REFERENCES Books(BookID),
    AuthorshipType VARCHAR(20)
);

-- loan time limit
CREATE OR REPLACE FUNCTION check_loan_dates() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.DueDate < NEW.LoanDate THEN
        RAISE EXCEPTION 'Due date must be after loan date';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_loan_dates_trigger
BEFORE INSERT ON BookLoans
FOR EACH ROW EXECUTE FUNCTION check_loan_dates();

--limiting the number of loans per person
CREATE OR REPLACE FUNCTION check_user_loan_limit() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM BookLoans WHERE UserID = NEW.UserID) >= 3 THEN
        RAISE EXCEPTION 'User can borrow up to 3 books at a time';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_user_loan_limit_trigger
BEFORE INSERT ON BookLoans
FOR EACH ROW EXECUTE FUNCTION check_user_loan_limit();

--ISO/IEC gender check
ALTER TABLE Genders
ADD CONSTRAINT chk_valid_gender
CHECK (UPPER(GenderName) IN ('MALE', 'FEMALE', 'NOT APPLICABLE', 'NOT KNOWN'));



-- booktype check
ALTER TABLE BookTypes
ADD CONSTRAINT chk_valid_book_type
CHECK (UPPER(TypeName) IN ('READING MATERIAL', 'ART BOOK', 'SCIENCE BOOK', 'BIOGRAPHY', 'PROFESSIONAL BOOK'));

--autorship check
ALTER TABLE Authorship
ADD CONSTRAINT chk_valid_authorship_type
CHECK (UPPER(AuthorshipType) IN ('MAIN AUTHOR', 'CO-AUTHOR'));

--procedure for book loan
CREATE OR REPLACE PROCEDURE borrow_book(
    instance_id INT,
    user_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    loan_id INT;
    loan_start_date DATE;
    due_date DATE;
    is_weekend BOOLEAN;
    is_summer BOOLEAN;
    is_readingmaterial BOOLEAN;
    late_fee_per_day INT;
BEGIN
    SELECT EXTRACT(DOW FROM CURRENT_DATE) IN (0, 6) INTO is_weekend;

    SELECT EXTRACT(MONTH FROM CURRENT_DATE) BETWEEN 6 AND 9 INTO is_summer;

    SELECT COUNT(*)
    INTO is_readingmaterial
    FROM Book b
    INNER JOIN BookInstances bi ON b.BookID = bi.BookID
    WHERE bi.InstanceID = instance_id AND b.BookTypeID = 1; 

    IF is_summer THEN
        IF is_weekend THEN
            late_fee_per_day := 20;
        ELSE
            late_fee_per_day := 30; 
        END IF;
    ELSE
        IF is_textbook THEN
            late_fee_per_day := 50; 
        ELSE
            IF is_weekend THEN
                late_fee_per_day := 20;
            ELSE
                late_fee_per_day := 40; 
            END IF;
        END IF;
    END IF;

    loan_start_date := CURRENT_DATE;
    due_date := loan_start_date + INTERVAL '20 days';

    INSERT INTO BookLoans (InstanceID, UserID, StartDate, DueDate)
    VALUES (instance_id, user_id, loan_start_date, due_date)
    RETURNING LoanID INTO loan_id;

    RAISE NOTICE 'The book is successfully loaned. ID of loan: %, Start date: %, Due date: %', loan_id, loan_start_date, due_date;

END;
$$;

--seed
INSERT INTO BookTypes (TypeName) VALUES
    ('Reading Material'),
    ('Art Book'),
    ('Science Book'),
    ('Biography'),
    ('Professional Book');

INSERT INTO Genders (GenderID, GenderName) VALUES
    (1, 'Male'),
    (2, 'Female'),
    (0, 'Not Known'),
    (9, 'Not Applicable');

insert into Users (UserID, UserName) values (1, 'Callie');
insert into Users (UserID, UserName) values (2, 'Eydie');
insert into Users (UserID, UserName) values (3, 'Vi');
insert into Users (UserID, UserName) values (4, 'Franny');
insert into Users (UserID, UserName) values (5, 'Kimmi');
insert into Users (UserID, UserName) values (6, 'Fannie');
insert into Users (UserID, UserName) values (7, 'Buddie');
insert into Users (UserID, UserName) values (8, 'Godfry');
insert into Users (UserID, UserName) values (9, 'Heinrik');
insert into Users (UserID, UserName) values (10, 'Mayne');
insert into Users (UserID, UserName) values (11, 'Jasun');
insert into Users (UserID, UserName) values (12, 'Laura');
insert into Users (UserID, UserName) values (13, 'Kippy');
insert into Users (UserID, UserName) values (14, 'Ainsley');
insert into Users (UserID, UserName) values (15, 'Monro');
insert into Users (UserID, UserName) values (16, 'Jase');
insert into Users (UserID, UserName) values (17, 'Elonore');
insert into Users (UserID, UserName) values (18, 'Guy');
insert into Users (UserID, UserName) values (19, 'Justino');
insert into Users (UserID, UserName) values (20, 'Kala');
insert into Users (UserID, UserName) values (21, 'Brennan');
insert into Users (UserID, UserName) values (22, 'Jessalin');
insert into Users (UserID, UserName) values (23, 'Davide');
insert into Users (UserID, UserName) values (24, 'Anabal');
insert into Users (UserID, UserName) values (25, 'Alex');
insert into Users (UserID, UserName) values (26, 'Quintana');
insert into Users (UserID, UserName) values (27, 'Esmaria');
insert into Users (UserID, UserName) values (28, 'Yvor');
insert into Users (UserID, UserName) values (29, 'Angelika');
insert into Users (UserID, UserName) values (30, 'Gilbert');
insert into Users (UserID, UserName) values (31, 'Wilhelmina');
insert into Users (UserID, UserName) values (32, 'Selle');
insert into Users (UserID, UserName) values (33, 'Lindy');
insert into Users (UserID, UserName) values (34, 'Mimi');
insert into Users (UserID, UserName) values (35, 'Ailey');
insert into Users (UserID, UserName) values (36, 'Darell');
insert into Users (UserID, UserName) values (37, 'Galven');
insert into Users (UserID, UserName) values (38, 'Vania');
insert into Users (UserID, UserName) values (39, 'Eddy');
insert into Users (UserID, UserName) values (40, 'Kennedy');
insert into Users (UserID, UserName) values (41, 'Modesty');
insert into Users (UserID, UserName) values (42, 'Jeanine');
insert into Users (UserID, UserName) values (43, 'Enid');
insert into Users (UserID, UserName) values (44, 'Cherry');
insert into Users (UserID, UserName) values (45, 'Roxana');
insert into Users (UserID, UserName) values (46, 'Ralph');
insert into Users (UserID, UserName) values (47, 'Charmaine');
insert into Users (UserID, UserName) values (48, 'Felicle');
insert into Users (UserID, UserName) values (49, 'Armstrong');
insert into Users (UserID, UserName) values (50, 'Carmine');

insert into Countries (CountryID, CountryName, Population, AverageSalary) values (1, 'China', 32418101, 2454.3);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (2, 'Finland', 40302001, 1866.4);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (3, 'Afghanistan', 11370701, 534.7);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (4, 'Albania', 49034896, 2184.0);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (5, 'Brazil', 5368423, 976.5);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (6, 'Argentina', 40721585, 2838.4);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (7, 'Andorra', 7531856, 2944.8);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (8, 'Algeria', 14518104, 1235.7);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (9, 'Ethiopia', 13262499, 1376.4);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (10, 'Aland Islands', 31601310, 1486.8);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (11, 'Bahamas', 6151270, 825.8);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (12, 'Angola', 26950555, 2648.9);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (13, 'Azerbaijan', 3636878, 2760.2);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (14, 'Bahrain', 36518816, 2375.9);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (15, 'Bangledash', 8188338, 1296.5);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (16, 'Barbarados', 5421555, 2729.3);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (17, 'Cameroon', 48023688, 1603.7);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (18, 'Canada', 21092828, 2349.0);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (19, 'Czech Republic', 22810904, 2196.8);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (20, 'Burkina Faso', 5696543, 2007.1);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (21, 'Cocos Islands', 21435467, 490.5);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (22, 'Madagascar', 46839994, 696.7);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (23, 'Chad', 29881917, 775.3);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (24, 'Bosnia and Herzegovina', 24122782, 1133.0);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (25, 'El Salvador', 46372276, 2498.2);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (26, 'Costa Rica', 32832068, 789.4);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (27, 'Cyprus', 20376019, 940.3);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (28, 'China', 18504772, 2169.0);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (29, 'Brazil', 2750086, 986.3);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (30, 'Finland', 33094544, 1254.1);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (31, 'Azerbaijan', 23309296, 2307.0);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (32, 'Cyprus', 14513043, 2209.0);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (33, 'Egypt', 20560149, 1078.3);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (34, 'Germany', 9125622, 819.5);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (35, 'Croatia', 7358925, 2574.2);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (36, 'Cuba', 35092764, 536.2);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (37, 'Denmark', 37367416, 1676.5);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (38, 'Dominica', 43439909, 2439.6);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (39, 'Estonia', 33222163, 1019.4);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (40, 'Ethiopia', 35077320, 1393.3);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (41, 'France', 34668924, 755.5);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (42, 'Haiti', 31334297, 2906.7);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (43, 'Liberia', 30581640, 2954.8);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (44, 'Israel', 5220824, 2830.9);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (45, 'Nigeria', 6149390, 1446.8);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (46, 'Qatar', 11624577, 2996.5);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (47, 'Nepal', 46717021, 412.8);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (48, 'Sweden', 44912940, 1704.8);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (49, 'Russia', 16830960, 1330.0);
insert into Countries (CountryID, CountryName, Population, AverageSalary) values (50, 'Kosovo', 23667474, 730.7);

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library1', '08:00:00', '18:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library2', '09:30:00', '19:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library3', '10:00:00', '20:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library4', '08:30:00', '17:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library5', '10:00:00', '19:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library6', '09:00:00', '18:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library7', '11:00:00', '20:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library8', '08:00:00', '17:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library9', '10:30:00', '19:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library10', '09:00:00', '18:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library11', '08:30:00', '17:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library12', '10:30:00', '19:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library13', '09:00:00', '18:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library14', '08:30:00', '17:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library15', '10:00:00', '19:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library16', '09:00:00', '18:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library17', '11:00:00', '20:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library18', '08:00:00', '17:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library19', '10:30:00', '19:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library20', '09:00:00', '18:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library21', '09:30:00', '18:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library22', '10:00:00', '19:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library23', '11:00:00', '20:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library24', '08:30:00', '17:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library25', '10:00:00', '19:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library26', '09:00:00', '18:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library27', '11:00:00', '20:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library28', '08:00:00', '17:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library29', '10:30:00', '19:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library30', '09:00:00', '18:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library31', '08:30:00', '18:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library32', '10:00:00', '19:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library33', '11:00:00', '20:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library34', '08:00:00', '17:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library35', '10:30:00', '19:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library36', '09:00:00', '18:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library37', '11:00:00', '20:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library38', '08:30:00', '17:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library39', '10:00:00', '19:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library40', '09:00:00', '18:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library41', '08:00:00', '18:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library42', '09:30:00', '19:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library43', '10:00:00', '20:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library44', '08:30:00', '18:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library45', '10:30:00', '19:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library46', '09:00:00', '18:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library47', '11:00:00', '20:00:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library48', '08:30:00', '17:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library49', '10:00:00', '19:30:00');

INSERT INTO Libraries (LibraryName, StartTime, EndTime)
VALUES ('Library50', '09:00:00', '18:00:00');

insert into Books (BookID, Title, PublicationDate, BookTypeID) values (1, 'She Creature (Mermaid Chronicles Part 1: She Creature)', '2023-10-05', 5);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (2, 'Officer''s Ward (chambre des officiers, La)', '2023-04-07', 2);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (3, 'Billy Blazes, Esq.', '2023-11-04', 2);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (4, 'Seventh Sign, The', '2023-02-19', 4);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (5, 'Claymation Christmas Celebration, A', '2023-09-12', 4);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (6, 'Sweepers', '2023-10-08', 1);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (7, 'Ghost of Frankenstein, The', '2023-01-22', 4);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (8, 'Two Women (Ciociara, La)', '2023-09-21', 2);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (9, 'Storage 24', '2023-01-12', 2);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (10, 'Goodbye Girl, The', '2023-02-23', 5);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (11, 'Attack of the 50ft Cheerleader', '2023-11-30', 1);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (12, 'Shock Corridor', '2023-03-04', 2);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (13, 'Afternoon of a Torturer, The (Dupa-amiaza unui tortionar)', '2023-05-23', 2);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (14, 'Quicksand', '2023-09-20', 3);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (15, 'Counselor, The', '2023-04-04', 3);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (16, 'Corrina, Corrina', '2023-05-29', 5);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (17, 'Chained for Life', '2023-08-17', 2);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (18, 'Trance', '2023-04-21', 1);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (19, 'Phantom Lady', '2023-11-12', 3);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (20, 'Desert Flower', '2022-12-30', 1);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (21, 'Lady is Willing, The', '2023-05-25', 5);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (22, 'Public Access', '2023-06-10', 2);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (23, 'Storm of the Century', '2023-03-12', 3);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (24, 'Story Written with Water, A (Mizu de kakareta monogatari)', '2023-04-15', 5);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (25, 'Vixen!', '2023-08-26', 3);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (26, 'Down and Out with the Dolls', '2023-09-11', 2);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (27, 'Powerpuff Girls, The', '2023-04-13', 3);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (28, 'Antisocial', '2023-11-10', 5);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (29, 'Jesse James', '2023-04-26', 5);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (30, 'Mary Stevens M.D.', '2023-06-10', 4);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (31, 'B. Monkey', '2023-05-24', 4);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (32, 'Story of Three Loves, The', '2023-05-05', 1);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (33, 'Maid in Sweden', '2023-01-08', 5);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (34, 'God''s Sandbox (Tahara)', '2023-11-29', 3);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (35, 'Secret Policeman''s Other Ball, The', '2023-05-26', 1);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (36, 'Date Movie', '2023-03-16', 4);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (37, 'As Tears Go By (Wong gok ka moon)', '2023-01-25', 3);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (38, 'Global Metal', '2023-07-15', 2);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (39, 'Decameron, The (Decameron, Il)', '2023-10-12', 1);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (40, 'Ringu (Ring)', '2023-08-11', 5);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (41, 'Karlsson Brothers (Bröderna Karlsson)', '2023-02-24', 1);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (42, 'Someone Like You (Unnaipol Oruvan)', '2023-10-18', 1);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (43, 'Redemption: For Robbing the Dead', '2023-06-15', 5);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (44, 'The Emperor''s Club', '2023-09-04', 5);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (45, 'You, the Living (Du levande)', '2023-12-12', 1);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (46, 'Two Weeks in September', '2023-02-05', 3);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (47, '3rd Voice, The', '2023-03-04', 4);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (48, '100 Men and a Girl (One Hundred Men and a Girl)', '2023-08-23', 3);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (49, 'Alice''s Adventures in Wonderland', '2023-02-11', 4);
insert into Books (BookID, Title, PublicationDate, BookTypeID) values (50, 'Charlie Chan in the Secret Service', '2023-12-16', 5);

insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (1, 'Marylène', 'Claisse', '2023-10-10', 30, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (2, 'Inès', 'MacKain', '2023-08-11', 11, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (3, 'Publicité', 'Mence', '2023-06-01', 34, 0);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (4, 'Lucrèce', 'Dwane', '2023-06-10', 45, 2);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (5, 'Yáo', 'Froome', '2023-04-11', 7, 0);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (6, 'Rachèle', 'Easman', '2023-09-25', 5, 9);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (7, 'Maëlla', 'Menego', '2023-03-10', 38, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (8, 'Mélodie', 'Dobinson', '2023-12-20', 37, 9);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (9, 'Inès', 'Proffer', '2023-04-12', 7, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (10, 'Mylène', 'Malim', '2023-11-11', 18, 9);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (11, 'Tú', 'Boughey', '2023-02-26', 10, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (12, 'Mårten', 'Loughlin', '2023-12-16', 49, 9);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (13, 'Göran', 'Londesborough', '2023-06-04', 50, 2);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (14, 'Méline', 'Balogun', '2023-05-17', 34, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (15, 'Marie-ève', 'Addenbrooke', '2023-03-02', 9, 2);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (16, 'Görel', 'O''Fallowne', '2023-02-03', 24, 2);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (17, 'Mén', 'Tanti', '2023-04-17', 2, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (18, 'Léane', 'Godsafe', '2023-07-07', 33, 2);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (19, 'Mà', 'Peltzer', '2023-06-19', 28, 2);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (20, 'Björn', 'Tallet', '2023-03-22', 25, 2);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (21, 'Réjane', 'Woodward', '2023-06-01', 15, 2);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (22, 'Vérane', 'Jeannet', '2023-08-19', 43, 2);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (23, 'Illustrée', 'Rattrie', '2023-09-05', 45, 2);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (24, 'Ophélie', 'Shakle', '2023-10-16', 40, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (25, 'Aimée', 'Sotheby', '2023-09-20', 41, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (26, 'Maïté', 'Korous', '2023-06-12', 25, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (27, 'Mégane', 'Leatt', '2022-12-26', 30, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (28, 'Kuí', 'Shelborne', '2023-10-13', 47, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (29, 'Gwenaëlle', 'Dorow', '2023-03-12', 11, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (30, 'Cloé', 'Lerego', '2023-11-04', 32, 2);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (31, 'Eugénie', 'Belt', '2023-06-06', 13, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (32, 'Annotée', 'Giraldon', '2023-11-02', 26, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (33, 'Lauréna', 'Seden', '2022-12-26', 26, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (34, 'Tú', 'Brosenius', '2023-01-04', 14, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (35, 'Almérinda', 'Candelin', '2023-05-19', 19, 2);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (36, 'Wá', 'Southcomb', '2023-08-09', 12, 9);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (37, 'Pål', 'Orts', '2023-02-02', 36, 9);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (38, 'Marlène', 'Denisard', '2023-02-25', 5, 9);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (39, 'Loïc', 'Lagne', '2023-06-04', 42, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (40, 'Dorothée', 'Terbruggen', '2023-07-21', 20, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (41, 'Illustrée', 'Dandie', '2022-12-23', 31, 0);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (42, 'Aloïs', 'Sherlock', '2023-04-02', 30, 0);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (43, 'Annotés', 'Maccari', '2023-06-27', 12, 9);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (44, 'Thérèsa', 'McFetrich', '2023-11-12', 8, 0);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (45, 'Loïca', 'Davidson', '2023-09-25', 37, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (46, 'Maïwenn', 'Ferrai', '2023-08-30', 27, 0);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (47, 'Méline', 'Screaton', '2023-03-25', 46, 9);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (48, 'Maëly', 'Neward', '2023-07-21', 3, 2);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (49, 'Pò', 'McQuin', '2023-12-06', 16, 1);
insert into Authors (AuthorID, AuthorName, Surname, DateOfBirth, CountryID, GenderID) values (50, 'Loïs', 'Robardey', '2023-02-17', 50, 9);


insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (1, 7, 12, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (2, 22, 35, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (3, 49, 2, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (4, 15, 28, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (5, 41, 41, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (6, 30, 5, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (7, 11, 17, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (8, 8, 46, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (9, 19, 23, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (10, 36, 9, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (11, 48, 38, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (12, 43, 15, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (13, 6, 19, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (14, 33, 10, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (15, 50, 27, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (16, 37, 20, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (17, 14, 33, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (18, 32, 6, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (19, 26, 14, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (20, 7, 42, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (21, 18, 36, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (22, 4, 25, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (23, 31, 44, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (24, 11, 24, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (25, 46, 7, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (26, 15, 35, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (27, 10, 12, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (28, 9, 17, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (29, 39, 46, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (30, 19, 48, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (31, 27, 2, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (32, 47, 32, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (33, 40, 50, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (34, 24, 5, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (35, 36, 43, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (36, 3, 21, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (37, 23, 23, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (38, 45, 28, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (39, 44, 9, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (40, 22, 11, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (41, 33, 33, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (42, 25, 47, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (43, 12, 42, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (44, 28, 18, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (45, 14, 31, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (46, 5, 38, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (47, 7, 14, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (48, 30, 30, 'Co-Author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (49, 17, 3, 'Main author');
insert into Authorship (AuthorshipID, AuthorID, BookID, AuthorshipType) values (50, 21, 20, 'Co-Author');

insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (1, 5, 17, 'Xy9kLpJQcFhsRvwzETOp');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (2, 31, 23, 'Nw4xvz1y2DsV0AUpb6qG');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (3, 20, 8, 'mS4PfYbLgWcn9KHJaZOQ');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (4, 46, 42, 'B6A2pUjJcXZLdo1Qa9hF');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (5, 17, 30, 'RvSfW1A3QkxMzD0UjL6N');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (6, 2, 15, 'VcIuG1zs9xNfw0oPmHqr');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (7, 12, 7, 'n0X3v5bKgFrwWjTNeLAJ');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (8, 26, 35, 'zQl8aVUjmbE1k6o0nS4F');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (9, 35, 21, '4LyR2h1NsZPCBn8J7YJa');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (10, 7, 2, 'Zr7eVXwL0I5xlKo4hH2d');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (11, 49, 16, 'C2A3BpFQ90wvUnkHRJ6x');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (12, 38, 11, 'hHjBwV7fG5KuNpM0YxR2');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (13, 44, 33, 'V9ZnqpxN4jO08AuzIak6');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (14, 28, 47, 'WjZ4lqnw0bA9mrKop2fD');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (15, 10, 26, 'rOcZpU5nm0Hb4XyQhEjA');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (16, 45, 29, 'Ix5hSd3KV6neA2fwB0tY');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (17, 24, 48, '8qP7dnVJlF2Ysx4rXeCB');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (18, 37, 6, 'NsWzq4a8mR5lHVoP9Ybj');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (19, 32, 19, 'FQwXmjK9hP5Blt0RZk2S');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (20, 16, 12, '0TzChwJcFN5IBvKPs1A4');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (21, 27, 46, 'BpF2cZ8Q9Y1Wxmj7K5dl');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (22, 30, 36, 'u5DvF7Sn2HQXIK1f8Zgb');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (23, 18, 10, 'TnkSdVm2bOFr1P3hK5jy');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (24, 25, 41, 'FJW6vQsyeZpBKfhtuYdU');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (25, 41, 45, 'm5ZlO8HdWyCjx1fR7PaQ');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (26, 42, 1, 'V7H8rNmkQIu0ZM2LxJ1g');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (27, 39, 39, 'J8HtkWMf4o7vneYQ5lDq');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (28, 19, 20, '2dC5wZo0Nr1pJhqVYl7U');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (29, 47, 44, 'z1a4HJcmK8XPVoFl0yMn');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (30, 6, 28, 'hI2zXynmkSJLpv3Bao0F');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (31, 13, 21, 'I5Hp7J2dtqDkQygn8msX');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (32, 26, 4, 'bNtUPrWQ4Z6Y7ksC0H9X');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (33, 36, 31, 'ofCBvJ0h1wpY6uI7g5rD');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (34, 1, 3, 'WmJFgWn5ZIvUcY1e4B2K');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (35, 15, 24, 'e7rJ5y2gW3uI4H8DtCvX');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (36, 22, 13, 'KJbgI6t2z4fn0wh1ocHX');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (37, 29, 38, '6Y7BhmJqkZ8CnXv3Qdtp');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (38, 43, 22, 'iKcMvQX2NpS5gZoRy6wH');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (39, 48, 50, 'oN74vHuXpIc1Jb3r5FqK');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (40, 14, 27, 'x2o8WpIbJgKvZ5T3yN1q');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (41, 9, 14, 'UpNkWsZI5mVjX6H4rGta');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (42, 3, 40, '9Xk2W3J6a4UIpZvYc8oH');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (43, 34, 35, 'uJN4XFwYp8mZ6vHoK0ia');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (44, 16, 5, 'nUkZoI2BfS5gJrTmX8Cv');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (45, 21, 37, 'S5pIcZ3UvJk4BmWnX2gR');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (46, 33, 9, 'CJmZ2K8XvN6oIpW5H3b1');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (47, 40, 43, 'K8X5I3pNvJkZoUcW2gRm');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (48, 4, 18, 'W6JpUcZ2XoNvK8I5B3rH');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (49, 23, 32, 'nBpZoU5vKmXcI8J2gRwH');
insert into BookInstances (InstanceID, BookID, LibraryID, InstanceCode) values (50, 50, 49, 'XNpZoU5vJkIcW8m2gR3H');

insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (1, 25, 17, '2023-06-10', '2023-06-17');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (2, 8, 38, '2023-05-18', '2023-05-25');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (3, 36, 3, '2023-07-02', '2023-07-09');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (4, 44, 11, '2023-08-14', '2023-08-21');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (5, 12, 50, '2023-11-30', '2023-12-07');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (6, 33, 7, '2023-02-01', '2023-02-08');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (7, 18, 45, '2023-09-10', '2023-09-17');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (8, 22, 12, '2023-04-05', '2023-04-12');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (9, 29, 27, '2023-08-22', '2023-08-29');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (10, 16, 32, '2023-03-15', '2023-03-22');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (11, 2, 41, '2023-12-18', '2023-12-25');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (12, 46, 29, '2023-09-01', '2023-09-08');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (13, 28, 1, '2023-02-15', '2023-02-22');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (14, 10, 13, '2023-06-23', '2023-07-30');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (15, 9, 36, '2023-11-05', '2023-11-12');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (16, 39, 8, '2023-07-14', '2023-07-21');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (17, 5, 16, '2023-04-08', '2023-04-15');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (18, 24, 48, '2023-01-20', '2023-01-27');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (19, 13, 42, '2023-03-29', '2023-04-05');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (20, 4, 30, '2023-10-10', '2023-10-17');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (21, 23, 14, '2023-08-05', '2023-08-12');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (22, 20, 6, '2023-05-28', '2023-06-04');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (23, 35, 22, '2023-11-15', '2023-11-22');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (24, 26, 35, '2023-02-08', '2023-02-15');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (25, 45, 24, '2023-07-25', '2023-08-01');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (26, 14, 17, '2023-06-10', '2023-06-17');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (27, 47, 39, '2023-06-10', '2023-06-17');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (28, 7, 46, '2023-09-02', '2023-09-09');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (29, 38, 5, '2023-04-20', '2023-04-27');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (30, 31, 18, '2023-01-10', '2023-01-17');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (31, 3, 28, '2023-08-18', '2023-08-25');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (32, 40, 47, '2023-05-05', '2023-05-12');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (33, 43, 33, '2023-11-28', '2023-12-05');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (34, 15, 9, '2023-03-05', '2023-03-12');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (35, 37, 25, '2023-06-18', '2023-06-25');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (36, 49, 2, '2023-09-20', '2023-09-27');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (37, 44, 31, '2023-02-23', '2023-03-02');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (38, 25, 20, '2023-11-08', '2023-11-15');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (39, 21, 12, '2023-04-15', '2023-04-22');
insert into BookLoans (LoanID, InstanceID, UserID, LoanDate, DueDate) values (40, 16, 44, '2023-07-28', '2023-08-04');