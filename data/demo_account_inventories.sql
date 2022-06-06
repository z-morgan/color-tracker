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
-- Name: inventories; Type: TABLE; Schema: public; Owner: zmorgan
--

CREATE TABLE public.inventories (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.inventories OWNER TO zmorgan;

--
-- Name: inventories_id_seq; Type: SEQUENCE; Schema: public; Owner: zmorgan
--

CREATE SEQUENCE public.inventories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventories_id_seq OWNER TO zmorgan;

--
-- Name: inventories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zmorgan
--

ALTER SEQUENCE public.inventories_id_seq OWNED BY public.inventories.id;


--
-- Name: inventories id; Type: DEFAULT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.inventories ALTER COLUMN id SET DEFAULT nextval('public.inventories_id_seq'::regclass);


--
-- Data for Name: inventories; Type: TABLE DATA; Schema: public; Owner: zmorgan
--

COPY public.inventories (id, user_id, name) FROM stdin;
40	43	Stylish Stuff Number 1
41	43	Stylish Stuff Number 2
\.


--
-- Name: inventories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zmorgan
--

SELECT pg_catalog.setval('public.inventories_id_seq', 41, true);


--
-- Name: inventories inventories_pkey; Type: CONSTRAINT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT inventories_pkey PRIMARY KEY (id);


--
-- Name: inventories inventories_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT inventories_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

