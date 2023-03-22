import { Stack, Typography } from '@mui/material';
import { EnteMenuItem } from 'components/Menu/menuItem';
import React from 'react';
import { PublicURL, Collection, UpdatePublicURL } from 'types/collection';
import constants from 'utils/strings/constants';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    updatePublicShareURLHelper: (req: UpdatePublicURL) => Promise<void>;
}

export function ManagePublicCollect({
    publicShareProp,
    updatePublicShareURLHelper,
    collection,
}: Iprops) {
    const handleFileDownloadSetting = () => {
        updatePublicShareURLHelper({
            collectionID: collection.id,
            enableCollect: !publicShareProp.enableCollect,
        });
    };

    return (
        <Stack>
            <EnteMenuItem
                onClick={handleFileDownloadSetting}
                color="primary"
                hasSwitch={true}
                checked={publicShareProp?.enableCollect}
                isTopOfList={true}
                isBottomOfList={true}>
                {constants.PUBLIC_COLLECT}
            </EnteMenuItem>
            <Typography
                color="text.secondary"
                variant="body2"
                paddingLeft={1.75}
                paddingTop={0.75}
                paddingBottom={0.75}>
                {constants.PUBLIC_COLLECT_SUBTEXT}
            </Typography>
        </Stack>
    );
}
