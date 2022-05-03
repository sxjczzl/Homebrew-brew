# typed: true
# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits formulae that are keg-only because they are provided by macos.
      class ProvidedByMacos < FormulaCop
        PROVIDED_BY_MACOS_FORMULAE = %w[
          apr
          bc
          berkeley-db
          bison
          bzip2
          cups
          curl
          cyrus-sasl
          dyld-headers
          ed
          expat
          file-formula
          flex
          gnu-getopt
          gperf
          icu4c
          krb5
          libarchive
          libedit
          libffi
          libiconv
          libpcap
          libressl
          libxcrypt
          libxml2
          libxslt
          llvm
          lsof
          m4
          ncompress
          ncurses
          net-snmp
          netcat
          openldap
          pcsc-lite
          pod2man
          rpcgen
          ruby
          sqlite
          ssh-copy-id
          swift
          tcl-tk
          texinfo
          unifdef
          unzip
          whois
          zip
          zlib
        ].freeze

        def on_formula_keg_only(node)
          return unless parameters_passed?(node, :provided_by_macos)
          return if PROVIDED_BY_MACOS_FORMULAE.include? @formula_name

          problem "Formulae that are `keg_only :provided_by_macos` should be "\
                  "added to the `PROVIDED_BY_MACOS_FORMULAE` list (in the Homebrew/brew repo)"
        end
      end

      # This cop audits `uses_from_macos` dependencies in formulae.
      class UsesFromMacos < FormulaCop
        # These formulae aren't `keg_only :provided_by_macos` but are provided by
        # macOS (or very similarly, e.g. OpenSSL where system provides LibreSSL).
        # TODO: consider making some of these keg-only.
        ALLOWED_USES_FROM_MACOS_DEPS = %w[
          bash
          cpio
          expect
          git
          groff
          gzip
          openssl
          perl
          php
          python
          rsync
          vim
          xz
          zsh
        ].freeze

        def on_formula_uses_from_macos(node)
          dep = if parameters(node).first.str_type?
            parameters(node).first
          elsif parameters(node).first.hash_type?
            parameters(node).first.keys.first
          end

          dep_name = string_content(dep)
          return if ALLOWED_USES_FROM_MACOS_DEPS.include? dep_name
          return if ProvidedByMacos::PROVIDED_BY_MACOS_FORMULAE.include? dep_name

          offending_node(node)
          problem "`uses_from_macos` should only be used for macOS dependencies, not #{dep_name}."
        end
      end
    end
  end
end
