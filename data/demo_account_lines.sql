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
-- Name: lines; Type: TABLE; Schema: public; Owner: zmorgan
--

CREATE TABLE public.lines (
    id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.lines OWNER TO zmorgan;

--
-- Name: lines_id_seq; Type: SEQUENCE; Schema: public; Owner: zmorgan
--

CREATE SEQUENCE public.lines_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lines_id_seq OWNER TO zmorgan;

--
-- Name: lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zmorgan
--

ALTER SEQUENCE public.lines_id_seq OWNED BY public.lines.id;


--
-- Name: lines id; Type: DEFAULT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.lines ALTER COLUMN id SET DEFAULT nextval('public.lines_id_seq'::regclass);


--
-- Data for Name: lines; Type: TABLE DATA; Schema: public; Owner: zmorgan
--

COPY public.lines (id, name) FROM stdin;
44	Wella
45	Difiaba
\.


--
-- Name: lines_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zmorgan
--

SELECT pg_catalog.setval('public.lines_id_seq', 45, true);


--
-- Name: lines lines_pkey; Type: CONSTRAINT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.lines
    ADD CONSTRAINT lines_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

