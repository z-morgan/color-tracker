--
-- PostgreSQL database dump
--

-- Dumped from database version 12.10 (Ubuntu 12.10-0ubuntu0.20.04.1)
-- Dumped by pg_dump version 12.10 (Ubuntu 12.10-0ubuntu0.20.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: users; Type: TABLE; Schema: public; Owner: zmorgan
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    password text NOT NULL,
    first_name character varying(50) NOT NULL
);


ALTER TABLE public.users OWNER TO zmorgan;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: zmorgan
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO zmorgan;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zmorgan
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: zmorgan
--

COPY public.users (id, username, password, first_name) FROM stdin;
43	stylishowl	$2a$12$DQ5pi6QA09dnVvTVsQ9QZ.sS.7hVWzJh..Kq8ddfbrD7CEPFcPrre	Stylish Owl
\.


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zmorgan
--

SELECT pg_catalog.setval('public.users_id_seq', 43, true);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- PostgreSQL database dump complete
--

