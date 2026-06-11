//
//  main.c
//  Extension
//
//  Created by Dave Hayden on 7/30/14.
//  Copyright (c) 2014 Panic, Inc. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>

#include "pd_api.h"

static int update(void* userdata);
LCDTileMap* tilemap;

#ifdef _WINDLL
__declspec(dllexport)
#endif
int eventHandler(PlaydateAPI* pd, PDSystemEvent event, uint32_t arg)
{
	(void)arg; // arg is currently only used for event = kEventKeyPressed

	if ( event == kEventInit )
	{
		tilemap = pd->graphics->tilemap->newTilemap();
		pd->graphics->tilemap->setSize(tilemap, 20, 12);
		
		LCDBitmapTable* table = pd->graphics->loadBitmapTable("font", NULL);
		pd->graphics->tilemap->setImageTable(tilemap, table);
		
		pd->system->setUpdateCallback(update, pd);
	}
	
	return 0;
}

static int update(void* userdata)
{
	PlaydateAPI* pd = userdata;
	
	pd->graphics->clear(kColorWhite);
	
	pd->graphics->tilemap->setTileAtPosition(tilemap, rand()%20, rand()%12, rand()%200);
	pd->graphics->tilemap->drawAtPoint(tilemap, 0, 0);

	return 1;
}
