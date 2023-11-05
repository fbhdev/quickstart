function create_component {
  local component_name="$1"
  echo "Creating component: $component_name.tsx"
  echo "import React from 'react';
import {motion} from 'framer-motion';

const enum Common {
  PARENT = ''
}

const enum Mobile {
  PARENT = \`\${Common.PARENT} p-4\`
}

const enum Desktop {
  PARENT = \`\${Common.PARENT} px-4 py-16\`
}

const ""$component_name"": React.FC<BaseComponent> = ({mobile}) => {
  return (
    <motion.div className={mobile ? Mobile.PARENT : Desktop.PARENT}>

    </motion.div>
  );
}

""$component_name"".displayName = ""$component_name"";
export default React.memo(""$component_name"");
" >>"$component_name.tsx"
  echo "Finished creating ""$component_name.tsx"""
}

function main {
  if [ $# -eq 0 ]; then
    exit 1
  fi

  local component_name="$1"
  create_component "$component_name"
}

main "$@"
