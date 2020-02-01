--
-- PostgreSQL database dump
--

-- Dumped from database version 12.1
-- Dumped by pg_dump version 12.1

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

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_keys (
    user_id integer NOT NULL,
    key character varying(255) NOT NULL,
    source character varying(255),
    actions integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    comment text,
    revoked boolean DEFAULT false NOT NULL,
    revoked_at timestamp without time zone,
    last_used_at timestamp without time zone
);


ALTER TABLE public.api_keys OWNER TO postgres;

--
-- Name: approved_labels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.approved_labels (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.approved_labels OWNER TO postgres;

--
-- Name: approved_labels_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.approved_labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.approved_labels_id_seq OWNER TO postgres;

--
-- Name: approved_labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.approved_labels_id_seq OWNED BY public.approved_labels.id;


--
-- Name: dependencies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dependencies (
    version_id integer NOT NULL,
    dependency_name character varying(255) NOT NULL,
    dependency character varying(255) NOT NULL
);


ALTER TABLE public.dependencies OWNER TO postgres;

--
-- Name: downloads_daily; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.downloads_daily (
    version_id integer NOT NULL,
    date date NOT NULL,
    count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.downloads_daily OWNER TO postgres;

--
-- Name: endorsements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.endorsements (
    user_id integer NOT NULL,
    module_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.endorsements OWNER TO postgres;

--
-- Name: exception_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exception_requests (
    id integer NOT NULL,
    exception_type_id integer NOT NULL,
    path text NOT NULL,
    method character varying(255) NOT NULL,
    referer text,
    ip character varying(255) NOT NULL,
    data text NOT NULL,
    msg text NOT NULL,
    trace text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.exception_requests OWNER TO postgres;

--
-- Name: exception_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exception_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.exception_requests_id_seq OWNER TO postgres;

--
-- Name: exception_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exception_requests_id_seq OWNED BY public.exception_requests.id;


--
-- Name: exception_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exception_types (
    id integer NOT NULL,
    label text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.exception_types OWNER TO postgres;

--
-- Name: exception_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exception_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.exception_types_id_seq OWNER TO postgres;

--
-- Name: exception_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exception_types_id_seq OWNED BY public.exception_types.id;


--
-- Name: followings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.followings (
    source_user_id integer NOT NULL,
    object_type smallint NOT NULL,
    object_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    type smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.followings OWNER TO postgres;

--
-- Name: github_accounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.github_accounts (
    user_id integer NOT NULL,
    github_login text NOT NULL,
    github_user_id integer DEFAULT 0 NOT NULL,
    access_token text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.github_accounts OWNER TO postgres;

--
-- Name: lapis_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lapis_migrations (
    name character varying(255) NOT NULL
);


ALTER TABLE public.lapis_migrations OWNER TO postgres;

--
-- Name: linked_modules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.linked_modules (
    module_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.linked_modules OWNER TO postgres;

--
-- Name: manifest_admins; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.manifest_admins (
    user_id integer NOT NULL,
    manifest_id integer NOT NULL,
    is_owner boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.manifest_admins OWNER TO postgres;

--
-- Name: manifest_backups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.manifest_backups (
    id integer NOT NULL,
    manifest_id integer NOT NULL,
    development boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_backup timestamp without time zone,
    repository_url text NOT NULL
);


ALTER TABLE public.manifest_backups OWNER TO postgres;

--
-- Name: manifest_backups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.manifest_backups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.manifest_backups_id_seq OWNER TO postgres;

--
-- Name: manifest_backups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.manifest_backups_id_seq OWNED BY public.manifest_backups.id;


--
-- Name: manifest_modules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.manifest_modules (
    manifest_id integer NOT NULL,
    module_id integer NOT NULL,
    module_name character varying(255) NOT NULL
);


ALTER TABLE public.manifest_modules OWNER TO postgres;

--
-- Name: manifests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.manifests (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    is_open boolean NOT NULL,
    display_name character varying(255),
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    modules_count integer DEFAULT 0 NOT NULL,
    versions_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.manifests OWNER TO postgres;

--
-- Name: manifests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.manifests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.manifests_id_seq OWNER TO postgres;

--
-- Name: manifests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.manifests_id_seq OWNED BY public.manifests.id;


--
-- Name: modules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modules (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying(255) NOT NULL,
    downloads integer DEFAULT 0 NOT NULL,
    current_version_id integer NOT NULL,
    summary character varying(255),
    description text,
    license character varying(255),
    homepage character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    display_name character varying(255),
    has_dev_version boolean DEFAULT false NOT NULL,
    followers_count integer DEFAULT 0 NOT NULL,
    labels text[],
    stars_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.modules OWNER TO postgres;

--
-- Name: modules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.modules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.modules_id_seq OWNER TO postgres;

--
-- Name: modules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.modules_id_seq OWNED BY public.modules.id;


--
-- Name: notification_objects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_objects (
    notification_id integer NOT NULL,
    object_type smallint NOT NULL,
    object_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.notification_objects OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    type integer DEFAULT 0 NOT NULL,
    object_type smallint NOT NULL,
    object_id integer NOT NULL,
    count integer DEFAULT 0 NOT NULL,
    seen boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_id_seq OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: rocks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rocks (
    id integer NOT NULL,
    version_id integer NOT NULL,
    arch character varying(255) NOT NULL,
    downloads integer DEFAULT 0 NOT NULL,
    rock_key character varying(255) NOT NULL,
    rock_fname character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    revision integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.rocks OWNER TO postgres;

--
-- Name: rocks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rocks_id_seq OWNER TO postgres;

--
-- Name: rocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rocks_id_seq OWNED BY public.rocks.id;


--
-- Name: user_activity_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_activity_logs (
    id integer NOT NULL,
    user_id integer NOT NULL,
    source smallint NOT NULL,
    action text NOT NULL,
    data json,
    ip inet,
    accept_lang text,
    user_agent text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    object_type smallint,
    object_id integer
);


ALTER TABLE public.user_activity_logs OWNER TO postgres;

--
-- Name: user_activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_activity_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_activity_logs_id_seq OWNER TO postgres;

--
-- Name: user_activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_activity_logs_id_seq OWNED BY public.user_activity_logs.id;


--
-- Name: user_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_data (
    user_id integer NOT NULL,
    email_verified boolean DEFAULT false NOT NULL,
    password_reset_token character varying(255),
    twitter text,
    website text,
    profile text,
    github text
);


ALTER TABLE public.user_data OWNER TO postgres;

--
-- Name: user_module_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_module_tags (
    user_id integer NOT NULL,
    module_id integer NOT NULL,
    tag character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.user_module_tags OWNER TO postgres;

--
-- Name: user_server_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_server_logs (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    log_date timestamp without time zone NOT NULL,
    log text NOT NULL,
    data json
);


ALTER TABLE public.user_server_logs OWNER TO postgres;

--
-- Name: user_server_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_server_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_server_logs_id_seq OWNER TO postgres;

--
-- Name: user_server_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_server_logs_id_seq OWNED BY public.user_server_logs.id;


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_sessions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    type smallint NOT NULL,
    revoked boolean DEFAULT false NOT NULL,
    ip inet NOT NULL,
    accept_lang text,
    user_agent text,
    last_active_at timestamp without time zone,
    revoked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.user_sessions OWNER TO postgres;

--
-- Name: user_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_sessions_id_seq OWNER TO postgres;

--
-- Name: user_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_sessions_id_seq OWNED BY public.user_sessions.id;


--
-- Name: user_sessions_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_sessions_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_sessions_user_id_seq OWNER TO postgres;

--
-- Name: user_sessions_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_sessions_user_id_seq OWNED BY public.user_sessions.user_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(255) NOT NULL,
    encrypted_password character varying(255),
    email character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    flags integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    following_count integer DEFAULT 0 NOT NULL,
    modules_count integer DEFAULT 0 NOT NULL,
    last_active_at timestamp without time zone,
    followers_count integer DEFAULT 0 NOT NULL,
    display_name character varying(255),
    stared_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.versions (
    id integer NOT NULL,
    module_id integer NOT NULL,
    version_name character varying(255) NOT NULL,
    rockspec_key character varying(255) NOT NULL,
    rockspec_fname character varying(255) NOT NULL,
    downloads integer DEFAULT 0 NOT NULL,
    rockspec_downloads integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    display_version_name character varying(255),
    lua_version character varying(255),
    development boolean DEFAULT false NOT NULL,
    source_url text,
    revision integer DEFAULT 1 NOT NULL,
    external_rockspec_url text,
    archived boolean DEFAULT false NOT NULL
);


ALTER TABLE public.versions OWNER TO postgres;

--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.versions_id_seq OWNER TO postgres;

--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: approved_labels id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.approved_labels ALTER COLUMN id SET DEFAULT nextval('public.approved_labels_id_seq'::regclass);


--
-- Name: exception_requests id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exception_requests ALTER COLUMN id SET DEFAULT nextval('public.exception_requests_id_seq'::regclass);


--
-- Name: exception_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exception_types ALTER COLUMN id SET DEFAULT nextval('public.exception_types_id_seq'::regclass);


--
-- Name: manifest_backups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manifest_backups ALTER COLUMN id SET DEFAULT nextval('public.manifest_backups_id_seq'::regclass);


--
-- Name: manifests id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manifests ALTER COLUMN id SET DEFAULT nextval('public.manifests_id_seq'::regclass);


--
-- Name: modules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules ALTER COLUMN id SET DEFAULT nextval('public.modules_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: rocks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rocks ALTER COLUMN id SET DEFAULT nextval('public.rocks_id_seq'::regclass);


--
-- Name: user_activity_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_activity_logs ALTER COLUMN id SET DEFAULT nextval('public.user_activity_logs_id_seq'::regclass);


--
-- Name: user_server_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_server_logs ALTER COLUMN id SET DEFAULT nextval('public.user_server_logs_id_seq'::regclass);


--
-- Name: user_sessions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN id SET DEFAULT nextval('public.user_sessions_id_seq'::regclass);


--
-- Name: user_sessions user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN user_id SET DEFAULT nextval('public.user_sessions_user_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (key);


--
-- Name: approved_labels approved_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.approved_labels
    ADD CONSTRAINT approved_labels_pkey PRIMARY KEY (id);


--
-- Name: dependencies dependencies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dependencies
    ADD CONSTRAINT dependencies_pkey PRIMARY KEY (version_id, dependency_name);


--
-- Name: downloads_daily downloads_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.downloads_daily
    ADD CONSTRAINT downloads_daily_pkey PRIMARY KEY (version_id, date);


--
-- Name: endorsements endorsements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.endorsements
    ADD CONSTRAINT endorsements_pkey PRIMARY KEY (user_id, module_id);


--
-- Name: exception_requests exception_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exception_requests
    ADD CONSTRAINT exception_requests_pkey PRIMARY KEY (id);


--
-- Name: exception_types exception_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exception_types
    ADD CONSTRAINT exception_types_pkey PRIMARY KEY (id);


--
-- Name: followings followings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.followings
    ADD CONSTRAINT followings_pkey PRIMARY KEY (source_user_id, object_type, object_id, type);


--
-- Name: github_accounts github_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.github_accounts
    ADD CONSTRAINT github_accounts_pkey PRIMARY KEY (user_id, github_user_id);


--
-- Name: lapis_migrations lapis_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lapis_migrations
    ADD CONSTRAINT lapis_migrations_pkey PRIMARY KEY (name);


--
-- Name: linked_modules linked_modules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.linked_modules
    ADD CONSTRAINT linked_modules_pkey PRIMARY KEY (module_id, user_id);


--
-- Name: manifest_admins manifest_admins_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manifest_admins
    ADD CONSTRAINT manifest_admins_pkey PRIMARY KEY (user_id, manifest_id);


--
-- Name: manifest_backups manifest_backups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manifest_backups
    ADD CONSTRAINT manifest_backups_pkey PRIMARY KEY (id);


--
-- Name: manifest_modules manifest_modules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manifest_modules
    ADD CONSTRAINT manifest_modules_pkey PRIMARY KEY (manifest_id, module_id);


--
-- Name: manifests manifests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manifests
    ADD CONSTRAINT manifests_pkey PRIMARY KEY (id);


--
-- Name: modules modules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_pkey PRIMARY KEY (id);


--
-- Name: notification_objects notification_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_objects
    ADD CONSTRAINT notification_objects_pkey PRIMARY KEY (notification_id, object_type, object_id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: rocks rocks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rocks
    ADD CONSTRAINT rocks_pkey PRIMARY KEY (id);


--
-- Name: user_activity_logs user_activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_activity_logs
    ADD CONSTRAINT user_activity_logs_pkey PRIMARY KEY (id);


--
-- Name: user_data user_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_data
    ADD CONSTRAINT user_data_pkey PRIMARY KEY (user_id);


--
-- Name: user_module_tags user_module_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_module_tags
    ADD CONSTRAINT user_module_tags_pkey PRIMARY KEY (user_id, module_id, tag);


--
-- Name: user_server_logs user_server_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_server_logs
    ADD CONSTRAINT user_server_logs_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: api_keys_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX api_keys_user_id_idx ON public.api_keys USING btree (user_id);


--
-- Name: approved_labels_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX approved_labels_name_idx ON public.approved_labels USING btree (name);


--
-- Name: dependencies_dependency_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX dependencies_dependency_name_idx ON public.dependencies USING btree (dependency_name);


--
-- Name: exception_requests_exception_type_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX exception_requests_exception_type_id_idx ON public.exception_requests USING btree (exception_type_id);


--
-- Name: exception_types_label_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX exception_types_label_idx ON public.exception_types USING btree (label);


--
-- Name: followings_object_type_object_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX followings_object_type_object_id_idx ON public.followings USING btree (object_type, object_id);


--
-- Name: manifest_modules_manifest_id_module_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX manifest_modules_manifest_id_module_name_idx ON public.manifest_modules USING btree (manifest_id, module_name);


--
-- Name: manifest_modules_module_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX manifest_modules_module_id_idx ON public.manifest_modules USING btree (module_id);


--
-- Name: manifests_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX manifests_name_idx ON public.manifests USING btree (name);


--
-- Name: module_search_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX module_search_idx ON public.modules USING gin (to_tsvector('english'::regconfig, (((((COALESCE(display_name, name))::text || ' '::text) || (COALESCE(summary, ''::character varying))::text) || ' '::text) || COALESCE(description, ''::text))));


--
-- Name: modules_downloads_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX modules_downloads_idx ON public.modules USING btree (downloads);


--
-- Name: modules_labels_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX modules_labels_idx ON public.modules USING gin (labels) WHERE (modules.* IS NOT NULL);


--
-- Name: modules_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX modules_name_idx ON public.modules USING btree (name);


--
-- Name: modules_name_search_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX modules_name_search_idx ON public.modules USING gin (COALESCE(display_name, name) public.gin_trgm_ops);


--
-- Name: modules_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX modules_user_id_idx ON public.modules USING btree (user_id);


--
-- Name: modules_user_id_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX modules_user_id_name_idx ON public.modules USING btree (user_id, name);


--
-- Name: notifications_user_id_seen_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notifications_user_id_seen_id_idx ON public.notifications USING btree (user_id, seen, id);


--
-- Name: notifications_user_id_type_object_type_object_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX notifications_user_id_type_object_type_object_id_idx ON public.notifications USING btree (user_id, type, object_type, object_id) WHERE (NOT seen);


--
-- Name: rocks_rock_fname_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX rocks_rock_fname_idx ON public.rocks USING btree (rock_fname);


--
-- Name: rocks_rock_key_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX rocks_rock_key_idx ON public.rocks USING btree (rock_key);


--
-- Name: rocks_version_id_arch_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX rocks_version_id_arch_idx ON public.rocks USING btree (version_id, arch);


--
-- Name: user_activity_logs_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_activity_logs_user_id_created_at_idx ON public.user_activity_logs USING btree (user_id, created_at);


--
-- Name: user_module_tags_module_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_module_tags_module_id_idx ON public.user_module_tags USING btree (module_id);


--
-- Name: user_server_logs_user_id_log_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_server_logs_user_id_log_date_idx ON public.user_server_logs USING btree (user_id, log_date);


--
-- Name: user_sessions_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_sessions_user_id_idx ON public.user_sessions USING btree (user_id);


--
-- Name: users_flags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX users_flags_idx ON public.users USING btree (flags);


--
-- Name: users_lower_email_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX users_lower_email_idx ON public.users USING btree (lower((email)::text));


--
-- Name: users_lower_username_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX users_lower_username_idx ON public.users USING btree (lower((username)::text));


--
-- Name: users_slug_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX users_slug_idx ON public.users USING btree (slug);


--
-- Name: users_username_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX users_username_idx ON public.users USING gin (username public.gin_trgm_ops);


--
-- Name: versions_downloads_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX versions_downloads_idx ON public.versions USING btree (downloads);


--
-- Name: versions_module_id_version_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX versions_module_id_version_name_idx ON public.versions USING btree (module_id, version_name);


--
-- Name: versions_rockspec_fname_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX versions_rockspec_fname_idx ON public.versions USING btree (rockspec_fname);


--
-- Name: versions_rockspec_key_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX versions_rockspec_key_idx ON public.versions USING btree (rockspec_key);


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 12.1
-- Dumped by pg_dump version 12.1

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

--
-- Data for Name: lapis_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lapis_migrations (name) FROM stdin;
1370275336
1370277180
1393557726
1401338238
1401600469
1401727722
1401810343
1408086639
1413268904
1423334387
1427443263
1427444511
1427445542
1427448938
1437970205
1438259102
1438314813
1438999272
1439449229
1439949273
1443373251
1443382411
1453406400
1462567085
1475034338
1475269875
1476481149
1496539644
1499055289
1499794884
1500093078
1500307302
1500308531
1500318771
1551765161
1551905631
1551918146
1551935898
1551990095
\.


--
-- PostgreSQL database dump complete
--

