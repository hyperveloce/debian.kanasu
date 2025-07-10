.PHONY: update-submodule

update-submodule:
	git submodule update --remote bootstrap
	git add bootstrap
	@if git diff --cached --quiet; then \
		echo "No updates to commit for submodule."; \
	else \
		git commit -m "Update bootstrap submodule"; \
		git push origin main; \
		echo "Submodule updated and pushed."; \
	fi
