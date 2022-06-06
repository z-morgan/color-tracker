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
-- Name: inventories_lines; Type: TABLE; Schema: public; Owner: zmorgan
--

CREATE TABLE public.inventories_lines (
    id integer NOT NULL,
    inventory_id integer NOT NULL,
    line_id integer NOT NULL
);


ALTER TABLE public.inventories_lines OWNER TO zmorgan;

--
-- Name: inventories_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: zmorgan
--

CREATE SEQUENCE public.inventories_lines_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventories_lines_id_seq OWNER TO zmorgan;

--
-- Name: inventories_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zmorgan
--

ALTER SEQUENCE public.inventories_lines_id_seq OWNED BY public.inventories_lines.id;


--
-- Name: inventories_lines id; Type: DEFAULT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.inventories_lines ALTER COLUMN id SET DEFAULT nextval('public.inventories_lines_id_seq'::regclass);


--
-- Data for Name: inventories_lines; Type: TABLE DATA; Schema: public; Owner: zmorgan
--

COPY public.inventories_lines (id, inventory_id, line_id) FROM stdin;
460	40	44
461	40	45
\.


--
-- Name: inventories_lines_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zmorgan
--

SELECT pg_catalog.setval('public.inventories_lines_id_seq', 461, true);


--
-- Name: inventories_lines inventories_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.inventories_lines
    ADD CONSTRAINT inventories_lines_pkey PRIMARY KEY (id);


--
-- Name: inventories_lines inventories_lines_inventory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.inventories_lines
    ADD CONSTRAINT inventories_lines_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES public.inventories(id) ON DELETE CASCADE;


--
-- Name: inventories_lines inventories_lines_line_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.inventories_lines
    ADD CONSTRAINT inventories_lines_line_id_fkey FOREIGN KEY (line_id) REFERENCES public.lines(id);


--
-- PostgreSQL database dump complete
--

