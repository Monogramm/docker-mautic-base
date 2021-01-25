#!/bin/bash
set -e

declare -A cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
	[fpm-alpine]='php-fpm'
)

declare -A extras=(
	[apache]='\n# Enable Apache Rewrite Module\nRUN a2enmod rewrite'
	[fpm]=''
	[fpm-alpine]=''
)

declare -A base=(
	[apache]='debian'
	[fpm]='debian'
	[fpm-alpine]='alpine'
)

variants=(
	apache
	fpm
)

echo "get latest version"
latest=$( curl -fsSL 'https://api.github.com/repos/mautic/mautic/tags' |tac|tac| \
	grep -oE '[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+' | \
	sort -urV | \
	head -n 1 )
version=$(echo "$latest" | cut -d. -f1-2)
major=$(echo "$latest" | cut -d. -f1-1)

dockerLatest='3.2'

# TODO - Expose SHA signatures for the packages somewhere
echo "get $latest SHA signature"
curl -o mautic.zip -SL "https://github.com/mautic/mautic/releases/download/$latest/$latest.zip"
sha1="$(sha1sum mautic.zip | sed -r 's/ .*//')"

echo "remove mautic.zip"
rm mautic.zip

echo "get $latest src SHA signature"
curl -o mautic-src.zip -SL "https://github.com/mautic/mautic/archive/$latest.zip"
srcsha1="$(sha1sum mautic-src.zip | sed -r 's/ .*//')"

echo "remove mautic-src.zip"
rm mautic-src.zip

echo "update docker images"
travisEnv=
for variant in "${variants[@]}"; do
	dir="$variant"
	echo "generating $latest-$variant"

	template="Dockerfile-${base[$variant]}.template"
	cp $template "$dir/Dockerfile"

	# To make management easier, we use these files for all variants
	cp -r common/* "$dir/"

	sed -E -i'' -e '
		s/%%VARIANT%%/'"$variant"'/;
		s/%%VARIANT_EXTRAS%%/'"${extras[$variant]}"'/;
		s/%%VERSION%%/'"$latest"'/;
		s/%%VERSION_SHA1%%/'"$sha1"'/;
		s/%%VERSION_SRC_SHA1%%/'"$srcsha1"'/;
		s/%%CMD%%/'"${cmd[$variant]}"'/;
	' "$dir/Dockerfile"

	# Create a list of "alias" tags for DockerHub post_push
	if [ "$version" = "$dockerLatest" ]; then
		if [ "$variant" = 'apache' ]; then
			export DOCKER_TAGS="$latest-$variant $version-$variant $major-$variant $variant $latest $version $major latest "
		else
			export DOCKER_TAGS="$latest-$variant $version-$variant $major-$variant $variant "
		fi
	else
		if [ "$variant" = 'apache' ]; then
			export DOCKER_TAGS="$latest-$variant $version-$variant $major-$variant $latest $version "
		else
			export DOCKER_TAGS="$latest-$variant $version-$variant $major-$variant "
		fi
	fi
	echo "${DOCKER_TAGS}" > "$dir/.dockertags"

	# Add Travis-CI env var
	travisEnv='\n    - VARIANT='"$variant$travisEnv"
done

echo "update .travis.yml"
travis="$(awk -v 'RS=\n\n' '$1 == "env:" && $2 == "#" && $3 == "Environments" { $0 = "env: # Environments'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
