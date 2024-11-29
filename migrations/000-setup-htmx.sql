-- Create text/html domain if not exists
create domain "text/html" as text;

-- HTML sanitization helper
create or replace function public.sanitize_html(text) returns text as $$
  select replace(replace(replace(replace(replace($1,
    '&', '&amp;'),
    '"', '&quot;'),
    '>', '>'),
    '<', '<'),
    '''', '&apos;')
$$ language sql;

create or replace function public.create_url(input text) returns text as $$
begin
  return lower(regexp_replace(
    regexp_replace(
      regexp_replace(input, '\s+', '-', 'g'),  -- Convert spaces to hyphens
      '[^a-z\-]', '', 'g'                      -- Remove anything except lowercase letters and hyphens
    ),
    '\-+', '-', 'g'                            -- Replace multiple consecutive hyphens with single hyphen
  ));
end;
$$ language plpgsql;

-- A sanitizer for any inputs on the website to protect agains XSS etc
create or replace function public.sanitize_input(input text) returns text as $$
begin
  return regexp_replace(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          trim(input),
          E'[<>]|&(?![a-zA-Z]{1,6};)', '', 'g'
        ),
        '(javascript|vbscript|expression|on\w+)\s*[:=]', '', 'gi'
      ),
      '/(data|javascript):\s*[^\s]*/i', '', 'g'
    ),
    '\\\\', '&#92;', 'g'
  );
end;
$$ language plpgsql;
