import { describe, it, expect } from 'vitest';
import { slugify } from './slugify.js';

describe('slugify', () => {
  it('converts simple string to slug', () => {
    expect(slugify('Hello World')).toBe('hello-world');
  });

  it('handles already slugified input', () => {
    expect(slugify('hello-world')).toBe('hello-world');
  });

  it('removes special characters', () => {
    expect(slugify('Hello, World!')).toBe('hello-world');
  });

  it('trims whitespace', () => {
    expect(slugify('  hello world  ')).toBe('hello-world');
  });

  it('returns empty string for nullish input', () => {
    expect(slugify(null)).toBe('');
    expect(slugify(undefined)).toBe('');
    expect(slugify('')).toBe('');
  });

  it('collapses consecutive hyphens', () => {
    expect(slugify('hello   ---   world')).toBe('hello-world');
  });

  it('handles hyphens at start and end', () => {
    expect(slugify('---hello---')).toBe('hello');
  });
});
