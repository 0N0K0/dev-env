#!/bin/bash
# Script d'automatisation complète pour WordPress Bedrock
# Ce script installe Bedrock avec Composer global et configure l'environnement

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Lire la configuration depuis .env
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Fichier .env non trouvé${NC}"
    exit 1
fi

PROJECT_NAME=$(grep "^PROJECT_NAME=" .env | cut -d'=' -f2)
CREATE_CUSTOM_THEME=$(grep "^CREATE_CUSTOM_THEME=" .env | cut -d'=' -f2 2>/dev/null || echo "false")
USE_CUSTOM_BLOCKS=$(grep "^USE_CUSTOM_BLOCKS=" .env | cut -d'=' -f2 2>/dev/null || echo "false")

echo -e "${BLUE}🚀 Installation automatique WordPress Bedrock: $PROJECT_NAME${NC}"

# Installer WP-CLI
echo -e "\n${YELLOW}🔧 Vérification de WP-CLI...${NC}"
if ! command -v wp &> /dev/null; then
    echo -e "${CYAN}Installation de WP-CLI...${NC}"
    brew install wp-cli
    echo -e "${GREEN}✅ WP-CLI installé${NC}"
else
    echo -e "${GREEN}✅ WP-CLI déjà disponible${NC}"
fi

# Nettoyer les anciens dossiers api/ et app/
if [ -d "api" ]; then
    sudo rm -rf "api" 2>/dev/null || rm -rf "api" 2>/dev/null || true
    echo "   🗑️  Dossier api/ supprimé"
fi

if [ -d "app" ]; then
    sudo rm -rf "app" 2>/dev/null || rm -rf "app" 2>/dev/null || true
    echo "   🗑️  Dossier app/ supprimé"
fi

# Créer le projet Bedrock avec Composer global
echo -e "\n${YELLOW}🎨 Installation de WordPress Bedrock avec Composer...${NC}"
composer create-project roots/bedrock ./app
echo -e "${GREEN}✅ Projet Bedrock créé${NC}"

# Créer le fichier .env pour WordPress
echo -e "${CYAN}Configuration de l'environnement WordPress...${NC}"

# Générer des clés de sécurité WordPress
SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

# Récupérer les données de configuration depuis .env
DB_TYPE=$(grep "^DB_TYPE=" .env | cut -d'=' -f2)
DB_NAME=$(grep "^DB_NAME=" .env | cut -d'=' -f2)
DB_USER=$(grep "^DB_USER=" .env | cut -d'=' -f2)
DB_PASSWORD=$(grep "^DB_PASSWORD=" .env | cut -d'=' -f2)
DB_PORT=$(grep "^DB_PORT=" .env | cut -d'=' -f2)

# Configurer la base de données et l'environnement
cat > app/.env << EOF
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=${DB_TYPE}

WP_ENV=development
WP_HOME=http://localhost:8080
WP_SITEURL=\${WP_HOME}/wp

# Configuration des clés de sécurité
$SALTS
EOF

echo -e "${GREEN}✅ Configuration WordPress créée${NC}"

# Thème personnalisé
if [ "$CREATE_CUSTOM_THEME" = "true" ]; then
    echo -e "\n${YELLOW}🎨 Création du thème personnalisé...${NC}"
    
    THEME_NAME="${PROJECT_NAME}-theme"
    THEME_PATH="app/web/app/themes/$THEME_NAME"
    
    # Créer la structure du thème
    echo -e "${CYAN}📁 Création de la structure du thème...${NC}"
    mkdir -p "$THEME_PATH"
    
    # Créer un thème de blocks
    echo -e "${CYAN}🧱 Création du thème de blocks...${NC}"
    
    # Structure des dossiers
    mkdir -p "$THEME_PATH/templates"
    mkdir -p "$THEME_PATH/parts"
    mkdir -p "$THEME_PATH/patterns"
    mkdir -p "$THEME_PATH/blocks"
    mkdir -p "$THEME_PATH/assets/css"
    mkdir -p "$THEME_PATH/assets/js"
    
    # style.css
    cat > $THEME_PATH/style.css << EOF
/*
Theme Name: $PROJECT_NAME Block Theme
Description: Thème de blocks personnalisé pour $PROJECT_NAME avec support FSE
Version: 1.0
Requires at least: 6.0
Tested up to: 6.4
Requires PHP: 8.0
*/
EOF

    # theme.json
    cat > $THEME_PATH/theme.json << EOF
{
  "\$schema": "https://schemas.wp.org/trunk/theme.json",
  "version": 2,
  "settings": {
    "appearanceTools": true,
    "useRootPaddingAwareAlignments": true,
    "layout": {
      "contentSize": "840px",
      "wideSize": "1200px"
    },
    "color": {
      "palette": [
        {
          "color": "#000000",
          "name": "Base",
          "slug": "base"
        },
        {
          "color": "#ffffff", 
          "name": "Contrast",
          "slug": "contrast"
        },
        {
          "color": "#3B82F6",
          "name": "Primary",
          "slug": "primary"
        },
        {
          "color": "#64748B",
          "name": "Secondary", 
          "slug": "secondary"
        }
      ]
    },
    "typography": {
      "fontFamilies": [
        {
          "fontFamily": "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif",
          "name": "System Font",
          "slug": "system-font"
        }
      ],
      "fontSizes": [
        {
          "size": "1rem",
          "slug": "small"
        },
        {
          "size": "1.125rem", 
          "slug": "medium"
        },
        {
          "size": "1.75rem",
          "slug": "large"
        },
        {
          "size": "3rem",
          "slug": "x-large"
        }
      ]
    },
    "blocks": {
      "core/button": {
        "border": {
          "radius": true
        }
      }
    }
  },
  "styles": {
    "color": {
      "background": "var(--wp--preset--color--base)",
      "text": "var(--wp--preset--color--contrast)"
    },
    "typography": {
      "fontFamily": "var(--wp--preset--font-family--system-font)"
    }
  },
  "templateParts": [
    {
      "name": "header",
      "title": "Header",
      "area": "header"
    },
    {
      "name": "footer",
      "title": "Footer", 
      "area": "footer"
    }
  ]
}
EOF

    # functions.php
    cat > $THEME_PATH/functions.php << EOF
<?php
/**
 * Thème de blocks - Functions
 */

// Support des fonctionnalités WordPress
function ${PROJECT_NAME//-/_}_setup() {
    // Support des blocks et FSE
    add_theme_support('block-templates');
    add_theme_support('block-template-parts');
    add_theme_support('editor-styles');
    add_theme_support('wp-block-styles');
    add_theme_support('responsive-embeds');
    
    // Support des images
    add_theme_support('post-thumbnails');
    add_theme_support('custom-logo');
    
    // Support HTML5
    add_theme_support('html5', [
        'search-form',
        'comment-form', 
        'comment-list',
        'gallery',
        'caption',
        'script',
        'style'
    ]);
}
add_action('after_setup_theme', '${PROJECT_NAME//-/_}_setup');

// Enregistrer les styles et scripts
function ${PROJECT_NAME//-/_}_enqueue_assets() {
    wp_enqueue_style('${PROJECT_NAME//-/_}-style', get_stylesheet_uri(), [], '1.0');
    
    // Style de l'éditeur
    wp_enqueue_block_style('core/button', [
        'handle' => '${PROJECT_NAME//-/_}-button-style',
        'src' => get_theme_file_uri('assets/css/blocks.css'),
        'path' => get_theme_file_path('assets/css/blocks.css')
    ]);
    
    // Scripts pour les blocks personnalisés
    if (file_exists(get_template_directory() . '/dist/blocks.js')) {
        wp_enqueue_script(
            '${PROJECT_NAME//-/_}-blocks',
            get_template_directory_uri() . '/dist/blocks.js',
            ['wp-blocks', 'wp-element', 'wp-editor'],
            '1.0',
            true
        );
    }
}
add_action('wp_enqueue_scripts', '${PROJECT_NAME//-/_}_enqueue_assets');
add_action('enqueue_block_editor_assets', '${PROJECT_NAME//-/_}_enqueue_assets');
EOF

    # Templates HTML
    cat > $THEME_PATH/templates/index.html << EOF
<!-- wp:template-part {"slug":"header","tagName":"header"} /-->

<!-- wp:group {"tagName":"main","style":{"spacing":{"padding":{"top":"2rem","bottom":"2rem"}}},"layout":{"type":"constrained"}} -->
<main class="wp-block-group" style="padding-top:2rem;padding-bottom:2rem">
<!-- wp:query {"queryId":1,"query":{"perPage":10,"pages":0,"offset":0,"postType":"post","order":"desc","orderBy":"date","author":"","search":"","exclude":[],"sticky":"","inherit":true}} -->
<div class="wp-block-query">
<!-- wp:post-template -->
<!-- wp:post-title {"isLink":true} /-->
<!-- wp:post-date /-->
<!-- wp:post-excerpt /-->
<!-- /wp:post-template -->

<!-- wp:query-pagination -->
<!-- wp:query-pagination-previous /-->
<!-- wp:query-pagination-numbers /-->
<!-- wp:query-pagination-next /-->
<!-- /wp:query-pagination -->
</div>
<!-- /wp:query -->
</main>
<!-- /wp:group -->

<!-- wp:template-part {"slug":"footer","tagName":"footer"} /-->
EOF

    cat > $THEME_PATH/templates/single.html << EOF
<!-- wp:template-part {"slug":"header","tagName":"header"} /-->

<!-- wp:group {"tagName":"main","style":{"spacing":{"padding":{"top":"2rem","bottom":"2rem"}}},"layout":{"type":"constrained"}} -->
<main class="wp-block-group" style="padding-top:2rem;padding-bottom:2rem">
<!-- wp:post-title {"level":1} /-->
<!-- wp:post-date /-->
<!-- wp:post-content /-->
</main>
<!-- /wp:group -->

<!-- wp:template-part {"slug":"footer","tagName":"footer"} /-->
EOF

    cat > $THEME_PATH/templates/page.html << EOF
<!-- wp:template-part {"slug":"header","tagName":"header"} /-->

<!-- wp:group {"tagName":"main","style":{"spacing":{"padding":{"top":"2rem","bottom":"2rem"}}},"layout":{"type":"constrained"}} -->
<main class="wp-block-group" style="padding-top:2rem;padding-bottom:2rem">
<!-- wp:post-title {"level":1} /-->
<!-- wp:post-content /-->
</main>
<!-- /wp:group -->

<!-- wp:template-part {"slug":"footer","tagName":"footer"} /-->
EOF

    # Template Parts
    cat > $THEME_PATH/parts/header.html << EOF
<!-- wp:group {"align":"full","style":{"spacing":{"padding":{"top":"1rem","bottom":"1rem"}}},"backgroundColor":"base","textColor":"contrast","layout":{"type":"constrained"}} -->
<div class="wp-block-group alignfull has-contrast-color has-base-background-color has-text-color has-background" style="padding-top:1rem;padding-bottom:1rem">
<!-- wp:group {"layout":{"type":"flex","flexWrap":"nowrap","justifyContent":"space-between"}} -->
<div class="wp-block-group">
<!-- wp:site-title {"level":0} /-->
<!-- wp:navigation {"layout":{"type":"flex","setCascadingProperties":true,"justifyContent":"right"}} /-->
</div>
<!-- /wp:group -->
</div>
<!-- /wp:group -->
EOF

    cat > $THEME_PATH/parts/footer.html << EOF
<!-- wp:group {"align":"full","style":{"spacing":{"padding":{"top":"2rem","bottom":"2rem"}}},"backgroundColor":"secondary","textColor":"contrast","layout":{"type":"constrained"}} -->
<div class="wp-block-group alignfull has-contrast-color has-secondary-background-color has-text-color has-background" style="padding-top:2rem;padding-bottom:2rem">
<!-- wp:paragraph {"align":"center"} -->
<p class="has-text-align-center">© 2025 <!-- wp:site-title {"level":0} /-->. Créé avec un thème de blocks personnalisé.</p>
<!-- /wp:paragraph -->
</div>
<!-- /wp:group -->
EOF

    # CSS pour les blocks personnalisés
    cat > $THEME_PATH/assets/css/blocks.css << EOF
/* Styles personnalisés pour les blocks */
.wp-block-button__link {
    border-radius: 6px;
    transition: all 0.2s ease;
}

.wp-block-button__link:hover {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.wp-block-group {
    --wp--style--block-gap: 2rem;
}

/* Responsive */
@media (max-width: 768px) {
    .wp-block-group {
        --wp--style--block-gap: 1rem;
    }
}
EOF

    echo -e "${GREEN}✅ Thème personnalisé créé (activation automatique au démarrage)${NC}"
    
    # Blocks personnalisés avec React, Vite et TypeScript
    if [ "$USE_CUSTOM_BLOCKS" = "true" ]; then
        echo -e "\n${YELLOW}⚡ Configuration des blocks personnalisés (React + Vite + TypeScript)...${NC}"
        
        # Package.json pour blocks WordPress avec TypeScript
        cat > $THEME_PATH/package.json << EOF
{
  "name": "$THEME_NAME",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite build --watch",
    "build": "vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "@types/wordpress__blocks": "^12.5.0",
    "@types/wordpress__block-editor": "^11.5.0",
    "@types/wordpress__components": "^23.0.0",
    "@types/wordpress__i18n": "^4.2.0",
    "@vitejs/plugin-react": "^4.0.0",
    "typescript": "^5.0.0",
    "vite": "^4.4.0"
  },
  "dependencies": {
    "@wordpress/block-editor": "^12.0.0",
    "@wordpress/blocks": "^12.0.0", 
    "@wordpress/components": "^25.0.0",
    "@wordpress/element": "^5.0.0",
    "@wordpress/i18n": "^4.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  }
}
EOF

        # Configuration Vite pour blocks WordPress
        cat > $THEME_PATH/vite.config.ts << EOF
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist',
    rollupOptions: {
      input: 'src/blocks.tsx',
      output: {
        entryFileNames: 'blocks.js',
        assetFileNames: 'blocks.css'
      },
      external: [
        '@wordpress/blocks',
        '@wordpress/block-editor', 
        '@wordpress/components',
        '@wordpress/element',
        '@wordpress/i18n',
        'react',
        'react-dom'
      ]
    }
  },
  define: {
    'process.env.NODE_ENV': JSON.stringify('development')
  }
})
EOF

        # Configuration TypeScript
        cat > $THEME_PATH/tsconfig.json << EOF
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

        # Structure pour les blocks WordPress personnalisés
        mkdir -p "$THEME_PATH/src/blocks"
        mkdir -p "$THEME_PATH/src/components"
        
        # Point d'entrée pour les blocks personnalisés
        cat > "$THEME_PATH/src/blocks.tsx" << EOF
/**
 * Point d'entrée pour les blocks personnalisés WordPress
 */
import './blocks/hero-card';
EOF

        # Block Hero Card personnalisé
        mkdir -p "$THEME_PATH/src/blocks/hero-card"
        
        cat > "$THEME_PATH/src/blocks/hero-card/index.tsx" << EOF
import { registerBlockType } from '@wordpress/blocks';
import { useBlockProps, InspectorControls, MediaUpload, RichText } from '@wordpress/block-editor';
import { PanelBody, Button } from '@wordpress/components';
import { __ } from '@wordpress/i18n';
import './style.css';

interface Attributes {
    title: string;
    content: string;
    imageUrl: string;
    imageId: number;
}

registerBlockType('${PROJECT_NAME//-/_}/hero-card', {
    title: __('Hero Card', '${PROJECT_NAME//-/_}'),
    icon: 'format-image',
    category: 'design',
    attributes: {
        title: {
            type: 'string',
            default: 'Titre du Hero'
        },
        content: {
            type: 'string', 
            default: 'Description du contenu...'
        },
        imageUrl: {
            type: 'string',
            default: ''
        },
        imageId: {
            type: 'number',
            default: 0
        }
    },

    edit: ({ attributes, setAttributes }: { attributes: Attributes; setAttributes: Function }) => {
        const blockProps = useBlockProps({
            className: 'hero-card-block'
        });

        return (
            <div {...blockProps}>
                <InspectorControls>
                    <PanelBody title={__('Paramètres Hero Card', '${PROJECT_NAME//-/_}')}>
                        <MediaUpload
                            onSelect={(media: any) => {
                                setAttributes({
                                    imageUrl: media.url,
                                    imageId: media.id
                                });
                            }}
                            allowedTypes={['image']}
                            value={attributes.imageId}
                            render={({ open }: { open: Function }) => (
                                <Button onClick={open} variant="secondary">
                                    {attributes.imageUrl ? 'Changer l\'image' : 'Sélectionner une image'}
                                </Button>
                            )}
                        />
                    </PanelBody>
                </InspectorControls>

                <div className="hero-card">
                    {attributes.imageUrl && (
                        <div className="hero-card__image">
                            <img src={attributes.imageUrl} alt="" />
                        </div>
                    )}
                    <div className="hero-card__content">
                        <RichText
                            tagName="h2"
                            value={attributes.title}
                            onChange={(title: string) => setAttributes({ title })}
                            placeholder={__('Titre du Hero...', '${PROJECT_NAME//-/_}')}
                        />
                        <RichText
                            tagName="p"
                            value={attributes.content}
                            onChange={(content: string) => setAttributes({ content })}
                            placeholder={__('Description du contenu...', '${PROJECT_NAME//-/_}')}
                        />
                    </div>
                </div>
            </div>
        );
    },

    save: ({ attributes }: { attributes: Attributes }) => {
        const blockProps = useBlockProps.save({
            className: 'hero-card-block'
        });

        return (
            <div {...blockProps}>
                <div className="hero-card">
                    {attributes.imageUrl && (
                        <div className="hero-card__image">
                            <img src={attributes.imageUrl} alt="" />
                        </div>
                    )}
                    <div className="hero-card__content">
                        <RichText.Content tagName="h2" value={attributes.title} />
                        <RichText.Content tagName="p" value={attributes.content} />
                    </div>
                </div>
            </div>
        );
    }
});
EOF

        # CSS pour le block Hero Card
        cat > "$THEME_PATH/src/blocks/hero-card/style.css" << EOF
.hero-card-block {
    margin: 2rem 0;
}

.hero-card {
    display: flex;
    align-items: center;
    gap: 2rem;
    padding: 2rem;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    background: #ffffff;
}

.hero-card__image {
    flex: 0 0 300px;
}

.hero-card__image img {
    width: 100%;
    height: 200px;
    object-fit: cover;
    border-radius: 6px;
}

.hero-card__content {
    flex: 1;
}

.hero-card__content h2 {
    margin: 0 0 1rem 0;
    font-size: 1.75rem;
    color: #1e293b;
}

.hero-card__content p {
    margin: 0;
    color: #64748b;
    line-height: 1.6;
}

@media (max-width: 768px) {
    .hero-card {
        flex-direction: column;
        text-align: center;
    }
    
    .hero-card__image {
        flex: none;
    }
}
EOF

        # Installer les dépendances Node.js localement
        echo -e "${CYAN}📦 Installation des dépendances Node.js...${NC}"
        cd "$THEME_PATH" && npm install && cd ../../../../../..
        
        echo -e "${GREEN}✅ Blocks personnalisés configuré${NC}"
        echo -e "${CYAN}💡 Pour développer: cd $THEME_PATH && npm run dev${NC}"
    fi
    
    echo -e "${GREEN}✅ Thème personnalisé créé${NC}"
fi

echo -e "${CYAN}🛠️  Installation de WordPress...${NC}"
make build && make start && make install-wordpress

# Informations finales
echo -e "\n${GREEN}🦆 Installation WordPress Bedrock terminée avec succès !${NC}"
echo -e "\n${PURPLE}📋 Informations du projet :${NC}"
echo -e "  ${CYAN}Nom:${NC} $PROJECT_NAME"
echo -e "  ${CYAN}Type:${NC} WordPress Bedrock"
echo -e "  ${CYAN}Thème de blocks personnalisé:${NC} $CREATE_CUSTOM_THEME"
echo -e "  ${CYAN}Blocks personnalisés:${NC} $USE_CUSTOM_BLOCKS"
echo -e "\n${PURPLE}🗄️  Base de données :${NC}"
echo -e "  ${CYAN}Type:${NC} $DB_TYPE"
echo -e "  ${CYAN}Version:${NC} $DB_VERSION"
echo -e "  ${CYAN}Hôte:${NC} $DB_TYPE"
echo -e "  ${CYAN}Port:${NC} $DB_PORT"
echo -e "  ${CYAN}Utilisateur:${NC} $DB_USER"
echo -e "  ${CYAN}Nom de la base:${NC} $DB_NAME"

echo -e "\n${GREEN}✨ Votre environnement WordPress Bedrock est prêt !${NC}"