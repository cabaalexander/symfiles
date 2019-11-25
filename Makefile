# vim: ts=8:sw=8

###########
#         #
# Options #
#         #
###########
CSV		?=
PASSWORD	?=

#############
#           #
# Constants #
#           #
#############

SYM_OUT		:= "${HOME}/.dots/symlink-dst-paths.out"

# `Main Paths`
# ============
HOME_DIST	:= ${HOME}
DOTS_PATH	:= ${PWD}/dots
SECRETS_PATH	:= ${PWD}/secrets/

# `secrets`
# =========
SECRETS_IGNORE	:= ! -wholename "*.git/*" ! -name "Session.vim"
SECRETS_SRC	:= $(shell find $(SECRETS_PATH) -type f $(SECRETS_IGNORE) 2> /dev/null)
SECRETS_OUT	:= $(patsubst $(SECRETS_PATH)/%,$(HOME_DIST)/%,$(SECRETS_SRC))

# `SHs`
# =====
SH_FILES	:= $(shell ${PWD}/config/utils/find-sh-files.sh)

# `dots`
# ======
DOTS_IGNORE	:= \
	! -name "*.md" \
	! -path "*plugged/*" \
	! -name "Session.vim" \
	! -path "*.git*"
DOTS_SRC	:= $(shell find $(DOTS_PATH) -type f $(DOTS_IGNORE))
DOTS_OUT	:= $(patsubst $(DOTS_PATH)/%,$(HOME_DIST)/%,$(DOTS_SRC))

# `clean`
# =======
CLEAN_SRC	:= $(shell cat $(SYM_OUT) 2> /dev/null)

#############
#           #
# Functions #
#           #
#############

define do_symlink
	@mkdir -p $(dir $(1))
	@ln -sfv $(2) $(1)
	@#Last symlinks (For cleaning porpuse) ¯\_(ツ)_/¯
	@[ -f $(SYM_OUT) ] || touch $(SYM_OUT)
	@echo $(1).clean >> $(SYM_OUT)
endef

define do_update_repo
	@${PWD}/config/utils/update-repo.sh $(1) $(2)
	@${PWD}/config/utils/change-git-protocol.sh \
		$(addsuffix /.git/config,$(2))
endef

#########
#       #
# RuleZ #
#       #
#########

.PHONY: symlink
symlink: symlink-dots symlink-secrets

.PHONY: install
install: make-dots symlink
	@PASSWORD=$(PASSWORD) ./install.sh $(CSV)

.PHONY: make-dots
make-dots:
	@mkdir -p ${HOME}/.dots

.PHONY: symlink-secrets
symlink-secrets: make-dots $(SECRETS_OUT)
$(HOME_DIST)/%: $(SECRETS_PATH)/%
	$(call do_symlink,$@,$<)

.PHONY: symlink-dots
symlink-dots: make-dots $(DOTS_OUT)
$(HOME_DIST)/%: $(DOTS_PATH)/%
	$(call do_symlink,$@,$<)

.PHONY: symlink-update
symlink-update: clean symlink

.PHONY: clean
clean: $(CLEAN_SRC) post-clean
$(HOME_DIST)/%.clean:
	@printf "x "
	@sed 's/.clean//' <<<"$@" \
		| xargs rm -rfv

.PHONY: post-clean
post-clean:
	@rm -f $(SYM_OUT)

.PHONY: test
test:
	@shellcheck $(SH_FILES)

.PHONY: test-fix
test-fix:
	@shellcheck $(SH_FILES) \
		| grep "^In" \
		| cut -d' ' -f2 \
		| xargs nvim

.PHONY: log
log:
	@less ~/.dots/install-status.log

.PHONY: log-raw
log-raw:
	@less ~/.dots/install.log