#!/bin/bash

test_description='config-managed multihooks, including git-hook command'

. ./test-lib.sh

test_expect_success 'git hook rejects commands without a mode' '
	test_must_fail git hook pre-commit
'


test_expect_success 'git hook rejects commands without a hookname' '
	test_must_fail git hook list
'

test_expect_success 'setup hooks in global, and local' '
	git config --add --local hook.pre-commit.command "/path/ghi" &&
	git config --add --global hook.pre-commit.command "/path/def"
'

ROOT=
if test_have_prereq MINGW
then
	# In Git for Windows, Unix-like paths work only in shell scripts;
	# `git.exe`, however, will prefix them with the pseudo root directory
	# (of the Unix shell). Let's accommodate for that.
	ROOT="$(cd / && pwd)"
fi

test_expect_success 'git hook list orders by config order' '
	cat >expected <<-EOF &&
	global:	$ROOT/path/def
	local:	$ROOT/path/ghi
	EOF

	git hook list pre-commit >actual &&
	test_cmp expected actual
'

test_expect_success 'git hook list dereferences a hookcmd' '
	git config --add --local hook.pre-commit.command "abc" &&
	git config --add --global hookcmd.abc.command "/path/abc" &&

	cat >expected <<-EOF &&
	global:	$ROOT/path/def
	local:	$ROOT/path/ghi
	local:	$ROOT/path/abc
	EOF

	git hook list pre-commit >actual &&
	test_cmp expected actual
'

test_expect_success 'git hook list reorders on duplicate commands' '
	git config --add --local hook.pre-commit.command "/path/def" &&

	cat >expected <<-EOF &&
	local:	$ROOT/path/ghi
	local:	$ROOT/path/abc
	local:	$ROOT/path/def
	EOF

	git hook list pre-commit >actual &&
	test_cmp expected actual
'

test_expect_success 'git hook list --porcelain prints just the command' '
	cat >expected <<-\EOF &&
	/path/ghi
	/path/abc
	/path/def
	EOF

	git hook list --porcelain pre-commit >actual &&
	test_cmp expected actual
'

test_done
